classdef WDS_Optimizer_App < matlab.apps.AppBase

    % Properties corresponding to UI components
    properties (Access = private)
        UIFigure              matlab.ui.Figure
        LeftPanel             matlab.ui.container.Panel
        RightPanel            matlab.ui.container.Panel
        
        % Left Panel Components
        INPButton             matlab.ui.control.Button
        INPLabel              matlab.ui.control.Label
        DButton               matlab.ui.control.Button
        DLabel                matlab.ui.control.Label
        CostButton            matlab.ui.control.Button
        CostLabel             matlab.ui.control.Label
        
        % Algorithm Selection & Inputs
        AlgorithmDropDownLabel matlab.ui.control.Label
        AlgorithmDropDown     matlab.ui.control.DropDown
        NSEditField           matlab.ui.control.NumericEditField
        NSEditFieldLabel      matlab.ui.control.Label
        MaxGenEditField       matlab.ui.control.NumericEditField
        MaxGenEditFieldLabel  matlab.ui.control.Label
        
        % Constraint Input Controls
        PminEditField         matlab.ui.control.NumericEditField
        PminEditFieldLabel    matlab.ui.control.Label
        VmaxEditField         matlab.ui.control.NumericEditField
        VmaxEditFieldLabel    matlab.ui.control.Label
        
        % Fixed Pipes Controls
        FixedPipesEditField   matlab.ui.control.EditField
        FixedPipesLabel       matlab.ui.control.Label

        RunButton             matlab.ui.control.Button
        ExportButton          matlab.ui.control.Button
        StatusLabel           matlab.ui.control.Label
        
        % Right Panel Components (Tabbed Layout)
        TabGroup              matlab.ui.container.TabGroup
        CostTab               matlab.ui.container.Tab
        HydraulicsTab         matlab.ui.container.Tab
        
        % Tab 1 (Costs & Convergence)
        UIAxes                matlab.ui.control.UIAxes
        UITablePipes          matlab.ui.control.Table
        CostSummaryLabel      matlab.ui.control.Label
        
        % Tab 2 (Hydraulic Plots & Tables)
        PressureAxes          matlab.ui.control.UIAxes
        VelocityAxes          matlab.ui.control.UIAxes
        UITableNodes          matlab.ui.control.Table
        NodeStatusLabel       matlab.ui.control.Label
        
        % Internal Data Storage
        InpFileStr
        DFileStr
        CostFileStr
        OptimalDiameters
        BestCost
        NodePressures
        PipeVelocities
    end

    methods (Access = private)

        % --- File Selection Functions ---
        function SelectINPFile(app, ~)
            [file, path] = uigetfile('*.inp', 'Select EPANET .inp File');
            if ischar(file)
                fullPath = fullfile(path, file);
                fullPath = strrep(fullPath, '\', '/');
                
                if contains(fullPath, ' ')
                    uialert(app.UIFigure, ...
                        'The selected file path contains spaces. Please move the folder or file to a directory path without spaces.', ...
                        'File Path Error');
                    return;
                end
                app.InpFileStr = fullPath;
                app.INPLabel.Text = file;
            end
        end

        function SelectDFile(app, ~)
            [file, path] = uigetfile('*.txt', 'Select Diameters File (D.txt)');
            if ischar(file)
                app.DFileStr = fullfile(path, file);
                app.DLabel.Text = file;
            end
        end

        function SelectCostFile(app, ~)
            [file, path] = uigetfile('*.txt', 'Select Costs File (Cost.txt)');
            if ischar(file)
                app.CostFileStr = fullfile(path, file);
                app.CostLabel.Text = file;
            end
        end

        % --- Main Run Optimization ---
        function RunOptimization(app, ~)
            if isempty(app.InpFileStr) || isempty(app.DFileStr) || isempty(app.CostFileStr)
                uialert(app.UIFigure, 'Please load all required input files first!', 'Input Error');
                return;
            end

            app.StatusLabel.Text = 'Status: Running Optimization...';
            app.RunButton.Enable = 'off';
            drawnow;

            try
                % 1. Load Data
                Din  = load(app.DFileStr);
                Cost = load(app.CostFileStr);
                D    = Din * 25.4; % Convert inches to mm

                try
                    tempInpPath = 'C:\temp_network.inp';
                    copyfile(app.InpFileStr, tempInpPath, 'f');
                catch
                    tempInpPath = fullfile(pwd, 'temp_network.inp');
                    copyfile(app.InpFileStr, tempInpPath, 'f');
                end

                % 2. Open EPANET Engine
                d = epanet(tempInpPath);
                NP = d.getLinkPipeCount();
                NN = d.getNodeCount();

                L = zeros(NP, 1);
                InitialD = zeros(NP, 1);
                for i = 1:NP
                    L(i) = d.getLinkLength(i);
                    InitialD(i) = d.getLinkDiameter(i);
                end

                % 3. Parse Fixed Pipe IDs (Fixed with strtrim)
                fixedStr = strtrim(app.FixedPipesEditField.Value);
                fixedPipes = [];
                if ~isempty(fixedStr)
                    try
                        fixedPipes = str2num(fixedStr); %#ok<ST2NM>
                        fixedPipes = fixedPipes(fixedPipes >= 1 & fixedPipes <= NP);
                    catch
                        fixedPipes = [];
                    end
                end
                
                variablePipes = setdiff(1:NP, fixedPipes);

                % 4. Read Parameters & Constraints
                Params.NS   = app.NSEditField.Value;
                Params.Pmin = app.PminEditField.Value;
                Params.Vmax = app.VmaxEditField.Value;
                Params.FixedPipes = fixedPipes;
                Params.VariablePipes = variablePipes;
                Params.InitialD = InitialD;

                MaxGen      = app.MaxGenEditField.Value;
                SelectedAlg = app.AlgorithmDropDown.Value;

                % 5. Execution Router
                if strcmp(SelectedAlg, 'Genetic Algorithm (GA)')
                    [Score, Position, ~] = app.RunGA(d, D, NP, NN, L, Din, Cost, Params, MaxGen);
                else
                    [Score, Position, ~] = app.RunPSO(d, D, NP, NN, L, Din, Cost, Params, MaxGen);
                end

                app.BestCost = Score;
                app.OptimalDiameters = Position';

                % 6. Post-Processing Hydraulic Analysis
                d.setLinkDiameter(1:NP, app.OptimalDiameters);
                d.solveCompleteHydraulics();

                P = d.getNodePressure();
                types = d.getNodeType();
                junctions = strcmpi(types, 'JUNCTION');

                app.NodePressures = P(junctions);
                app.NodePressures = app.NodePressures(:); 

                V = d.getLinkVelocity();
                app.PipeVelocities = V(1:NP);
                app.PipeVelocities = app.PipeVelocities(:);

                d.unload();

                % Update Tab 1 Tables & Labels
                PipesList = (1:NP)';
                OptD = app.OptimalDiameters(:);

                TableDataPipes = table(PipesList, OptD, app.PipeVelocities, ...
                    'VariableNames', {'Pipe_ID', 'Diameter_mm', 'Velocity_m_s'});
                app.UITablePipes.Data = TableDataPipes;
                app.CostSummaryLabel.Text = sprintf('Optimal Cost: $%.2f', app.BestCost);

                % Update Tab 2 Tables & Plots
                numNodes = numel(app.NodePressures);
                NodeIDs = (1:numNodes)';
                PressureStatus = cell(numNodes, 1);
                pMinVal = Params.Pmin;
                vMaxVal = Params.Vmax;

                for k = 1:numNodes
                    pVal = app.NodePressures(k);
                    if pVal < pMinVal
                        PressureStatus{k} = sprintf('Violation (<%.1fm)', pMinVal);
                    else
                        PressureStatus{k} = 'Feasible (OK)';
                    end
                end

                TableDataNodes = table(NodeIDs, app.NodePressures, PressureStatus, ...
                    'VariableNames', {'Node_ID', 'Pressure_m', 'Status'});
                app.UITableNodes.Data = TableDataNodes;

                minP = min(app.NodePressures);
                maxV = max(app.PipeVelocities);
                app.NodeStatusLabel.Text = sprintf('Min P: %.2fm | Max V: %.2fm/s', minP, maxV);

                % --- Hydraulic Plots ---
                bar(app.PressureAxes, 1:numNodes, app.NodePressures, 0.6, 'FaceColor', [0 0.45 0.74]);
                yline(app.PressureAxes, pMinVal, '--r', sprintf('Pmin (%.1fm)', pMinVal), 'LineWidth', 1.5, 'FontWeight', 'bold');
                xlabel(app.PressureAxes, 'Node ID');
                ylabel(app.PressureAxes, 'Pressure (m)');
                title(app.PressureAxes, 'Node Pressure Profile');
                grid(app.PressureAxes, 'on');

                bar(app.VelocityAxes, 1:NP, app.PipeVelocities, 0.6, 'FaceColor', [0.47 0.67 0.19]);
                yline(app.VelocityAxes, vMaxVal, '--r', sprintf('Vmax (%.1fm/s)', vMaxVal), 'LineWidth', 1.5, 'FontWeight', 'bold');
                xlabel(app.VelocityAxes, 'Pipe ID');
                ylabel(app.VelocityAxes, 'Velocity (m/s)');
                title(app.VelocityAxes, 'Pipe Velocity Distribution');
                grid(app.VelocityAxes, 'on');

                app.StatusLabel.Text = 'Status: Completed Successfully!';
                app.ExportButton.Enable = 'on';

            catch ME
                app.StatusLabel.Text = 'Status: Error occurred!';
                uialert(app.UIFigure, ME.message, 'Execution Error');
            end

            app.RunButton.Enable = 'on';
        end

        % --- GA Engine ---
        function [Score, Position, Conv] = RunGA(app, d, D, NP, NN, L, Din, Cost, Params, MaxGen)
            Problem.d = d; Problem.D = D; Problem.NP = NP;
            Problem.NN = NN; Problem.L = L; Problem.Din = Din;
            Problem.Cost = Cost; Problem.Pmin = Params.Pmin; Problem.Vmax = Params.Vmax;
            Problem.FixedPipes = Params.FixedPipes;
            Problem.VariablePipes = Params.VariablePipes;
            Problem.InitialD = Params.InitialD;

            NS = Params.NS; Pc = 0.8; Pm = 0.03; ND = numel(D);
            NVar = numel(Problem.VariablePipes);
            Conv = zeros(MaxGen, 1);
            BestCostEver = Inf; BestSolEver = [];
            BestViolEver = Inf; BestUnfeasibleSol = []; BestUnfeasibleCost = Inf;

            Pop = randi(ND, NVar, NS);
            [cost, viol, feas] = app.evaluate_pop(Pop, Problem);

            for G = 1:MaxGen
                Fitness = app.calculate_fitness(cost, viol);
                SelectedIdx = app.selection_roulette(Fitness, NS);
                MatingPool = Pop(:, SelectedIdx);

                NewPop = MatingPool;
                for i = 1:2:NS-1
                    if rand < Pc && NVar > 1
                        cp = randi(NVar - 1);
                        NewPop(:, i)   = [MatingPool(1:cp, i); MatingPool(cp+1:end, i+1)];
                        NewPop(:, i+1) = [MatingPool(1:cp, i+1); MatingPool(cp+1:end, i)];
                    end
                end

                for i = 1:NS
                    for j = 1:NVar
                        if rand < Pm, NewPop(j, i) = randi(ND); end
                    end
                end

                if ~isempty(BestSolEver)
                    NewPop(:, 1) = BestSolEver;
                elseif ~isempty(BestUnfeasibleSol)
                    NewPop(:, 1) = BestUnfeasibleSol;
                end

                Pop = NewPop;
                [cost, viol, feas] = app.evaluate_pop(Pop, Problem);

                feasible_idx = find(feas);
                if ~isempty(feasible_idx)
                    [min_c, k] = min(cost(feasible_idx));
                    if min_c < BestCostEver
                        BestCostEver = min_c;
                        BestSolEver  = Pop(:, feasible_idx(k));
                    end
                end

                [min_v, idx_v] = min(viol);
                if min_v < BestViolEver
                    BestViolEver = min_v;
                    BestUnfeasibleSol = Pop(:, idx_v);
                    BestUnfeasibleCost = cost(idx_v);
                end

                if ~isempty(BestSolEver)
                    Conv(G) = BestCostEver;
                else
                    Conv(G) = BestUnfeasibleCost;
                end

                if mod(G, 5) == 0 || G == MaxGen
                    plot(app.UIAxes, 1:G, Conv(1:G), 'LineWidth', 2, 'Color', [0.85 0.32 0.1]);
                    xlabel(app.UIAxes, 'Generation');
                    ylabel(app.UIAxes, 'Best Cost ($)');
                    title(app.UIAxes, sprintf('GA Convergence (Gen %d/%d)', G, MaxGen));
                    grid(app.UIAxes, 'on');
                    drawnow;
                end
            end

            if isempty(BestSolEver)
                BestSolEver = BestUnfeasibleSol;
                BestCostEver = BestUnfeasibleCost;
                uialert(app.UIFigure, ...
                    'No fully feasible solution found. Displaying solution with minimum violation.', ...
                    'Constraint Alert', 'Icon', 'warning');
            end

            Score = BestCostEver;
            FullDiameters = Problem.InitialD;
            FullDiameters(Problem.VariablePipes) = D(BestSolEver);
            Position = FullDiameters';
        end

        % --- PSO Engine ---
        function [Score, Position, Conv] = RunPSO(app, d, D, NP, NN, L, Din, Cost, Params, MaxGen)
            Problem.d = d; Problem.D = D; Problem.NP = NP;
            Problem.NN = NN; Problem.L = L; Problem.Din = Din;
            Problem.Cost = Cost; Problem.Pmin = Params.Pmin; Problem.Vmax = Params.Vmax;
            Problem.FixedPipes = Params.FixedPipes;
            Problem.VariablePipes = Params.VariablePipes;
            Problem.InitialD = Params.InitialD;

            N = Params.NS; ND = numel(D); NVar = numel(Problem.VariablePipes);
            w = 0.7; c1 = 1.5; c2 = 1.5;

            X = randi(ND, NVar, N);
            V = zeros(NVar, N);

            PBestX = X;
            PBestCost = Inf(1, N);
            PBestViol = Inf(1, N);

            GBestX = []; GBestCost = Inf; GBestViol = Inf;
            Conv = zeros(MaxGen, 1);

            for G = 1:MaxGen
                X_discrete = round(X);
                X_discrete = max(1, min(ND, X_discrete));

                [cost, viol, feas] = app.evaluate_pop(X_discrete, Problem);

                for i = 1:N
                    if (feas(i) && cost(i) < PBestCost(i)) || (~feas(i) && viol(i) < PBestViol(i))
                        PBestCost(i) = cost(i);
                        PBestViol(i) = viol(i);
                        PBestX(:, i)  = X_discrete(:, i);
                    end

                    if (feas(i) && cost(i) < GBestCost) || (~feas(i) && viol(i) < GBestViol)
                        GBestCost = cost(i);
                        GBestViol = viol(i);
                        GBestX    = X_discrete(:, i);
                    end
                end

                for i = 1:N
                    r1 = rand(NVar, 1); r2 = rand(NVar, 1);
                    V(:, i) = w * V(:, i) + c1 * r1 .* (PBestX(:, i) - X(:, i)) + c2 * r2 .* (GBestX - X(:, i));
                    X(:, i) = X(:, i) + V(:, i);
                end

                Conv(G) = GBestCost;

                if mod(G, 5) == 0 || G == MaxGen
                    plot(app.UIAxes, 1:G, Conv(1:G), 'LineWidth', 2, 'Color', [0.0 0.45 0.74]);
                    xlabel(app.UIAxes, 'Iteration');
                    ylabel(app.UIAxes, 'Best Cost ($)');
                    title(app.UIAxes, sprintf('PSO Convergence (Iter %d/%d)', G, MaxGen));
                    grid(app.UIAxes, 'on');
                    drawnow;
                end
            end

            if GBestViol > 0
                uialert(app.UIFigure, ...
                    'No fully feasible solution found by PSO. Displaying solution with minimum violation.', ...
                    'Constraint Alert', 'Icon', 'warning');
            end

            Score = GBestCost;
            FullDiameters = Problem.InitialD;
            FullDiameters(Problem.VariablePipes) = D(GBestX);
            Position = FullDiameters';
        end

        % --- Export Data to Excel ---
        function ExportToExcel(app, ~)
            [file, path] = uiputfile('*.xlsx', 'Save Comprehensive Results as Excel');
            if ischar(file)
                fullFileName = fullfile(path, file);
                
                writetable(app.UITablePipes.Data, fullFileName, 'Sheet', 'Pipe_Optimization');
                writetable(app.UITableNodes.Data, fullFileName, 'Sheet', 'Hydraulic_Nodes');
                
                uialert(app.UIFigure, 'Pipes and Hydraulic Node results exported successfully!', 'Export Success');
            end
        end

        % --- Helpers ---
        function Fitness = calculate_fitness(~, cost, viol)
            Fitness = 1 ./ (cost + 2e6 * (viol .^ 2) + 1e-6);
        end

        function idx = selection_roulette(~, Fitness, NS)
            prob = Fitness / sum(Fitness);
            cum_prob = cumsum(prob);
            idx = zeros(1, NS);
            for i = 1:NS
                idx(i) = find(rand <= cum_prob, 1, 'first');
            end
        end

        function [cost, viol, feas] = evaluate_pop(app, Pop, Problem)
            NS = size(Pop, 2);
            cost = zeros(NS, 1); viol = zeros(NS, 1); feas = false(NS, 1);
            for i = 1:NS
                [cost(i), viol(i), feas(i)] = app.evaluate_ind(Pop(:, i), Problem);
            end
        end

        function [cost, viol, feas] = evaluate_ind(~, ind, Problem)
            d = Problem.d; D = Problem.D; NP = Problem.NP; L = Problem.L;
            Din = Problem.Din; Cost = Problem.Cost; 
            Pmin = Problem.Pmin; Vmax = Problem.Vmax;
            
            FullD = Problem.InitialD;
            FullD(Problem.VariablePipes) = D(ind);

            d.setLinkDiameter(1:NP, FullD');
            d.solveCompleteHydraulics();
            
            P = d.getNodePressure();
            types = d.getNodeType();
            Pj = P(strcmpi(types, 'JUNCTION'));
            
            V = d.getLinkVelocity();
            Vpipes = abs(V(1:NP));

            cost = 0;
            for i = Problem.VariablePipes
                Dmm = Din * 25.4;
                [~, idx] = min(abs(Dmm - FullD(i)));
                cost = cost + L(i) * Cost(idx);
            end

            p_viol = sum(max(0, Pmin - Pj));
            v_viol = sum(max(0, Vpipes - Vmax));
            
            viol = p_viol + v_viol;
            feas = (viol == 0);
        end
    end

    % Component initialization
    methods (Access = private)

        function createComponents(app)
            app.UIFigure = uifigure('Position', [100 100 980 660], 'Name', 'WDS Optimization Toolkit v1.5.0');

            app.LeftPanel  = uipanel(app.UIFigure, 'Title', 'Input Controls & Constraints', 'Position', [10 10 300 640]);
            app.RightPanel = uipanel(app.UIFigure, 'Title', 'Results & Hydraulic Analysis', 'Position', [320 10 650 640]);

            % File Selection
            app.INPButton  = uibutton(app.LeftPanel, 'push', 'Text', 'Load .INP File', 'Position', [20 570 120 28], 'ButtonPushedFcn', @(btn, e) SelectINPFile(app, e));
            app.INPLabel   = uilabel(app.LeftPanel, 'Text', 'No file selected', 'Position', [150 570 130 28]);

            app.DButton    = uibutton(app.LeftPanel, 'push', 'Text', 'Load D.txt', 'Position', [20 530 120 28], 'ButtonPushedFcn', @(btn, e) SelectDFile(app, e));
            app.DLabel     = uilabel(app.LeftPanel, 'Text', 'No file selected', 'Position', [150 530 130 28]);

            app.CostButton = uibutton(app.LeftPanel, 'push', 'Text', 'Load Cost.txt', 'Position', [20 490 120 28], 'ButtonPushedFcn', @(btn, e) SelectCostFile(app, e));
            app.CostLabel  = uilabel(app.LeftPanel, 'Text', 'No file selected', 'Position', [150 490 130 28]);

            % Algorithm Selection
            app.AlgorithmDropDownLabel = uilabel(app.LeftPanel, 'Text', 'Algorithm:', 'Position', [20 440 100 22], 'FontWeight', 'bold');
            app.AlgorithmDropDown      = uidropdown(app.LeftPanel, 'Position', [130 440 140 22], 'Items', {'Genetic Algorithm (GA)', 'Particle Swarm (PSO)'});

            % Algorithm Parameters
            app.NSEditFieldLabel = uilabel(app.LeftPanel, 'Text', 'Population / Swarm:', 'Position', [20 400 130 22]);
            app.NSEditField      = uieditfield(app.LeftPanel, 'numeric', 'Position', [160 400 100 22], 'Value', 100);

            app.MaxGenEditFieldLabel = uilabel(app.LeftPanel, 'Text', 'Max Gen / Iter:', 'Position', [20 365 130 22]);
            app.MaxGenEditField      = uieditfield(app.LeftPanel, 'numeric', 'Position', [160 365 100 22], 'Value', 500);

            % Constraints Controls
            app.PminEditFieldLabel = uilabel(app.LeftPanel, 'Text', 'Min Pressure (m):', 'Position', [20 315 130 22], 'FontWeight', 'bold');
            app.PminEditField      = uieditfield(app.LeftPanel, 'numeric', 'Position', [160 315 100 22], 'Value', 30.0);

            app.VmaxEditFieldLabel = uilabel(app.LeftPanel, 'Text', 'Max Velocity (m/s):', 'Position', [20 280 130 22], 'FontWeight', 'bold');
            app.VmaxEditField      = uieditfield(app.LeftPanel, 'numeric', 'Position', [160 280 100 22], 'Value', 2.5);

            % Fixed Pipes Input
            app.FixedPipesLabel     = uilabel(app.LeftPanel, 'Text', 'Fixed Pipe IDs (e.g. 1, 3):', 'Position', [20 235 150 22], 'FontWeight', 'bold');
            app.FixedPipesEditField = uieditfield(app.LeftPanel, 'text', 'Position', [170 235 90 22], 'Value', '');

            % Action Buttons
            app.RunButton    = uibutton(app.LeftPanel, 'push', 'Text', 'Run Optimization', 'Position', [20 150 250 42], 'BackgroundColor', [0.1 0.6 0.2], 'FontColor', 'w', 'FontSize', 14, 'FontWeight', 'bold', 'ButtonPushedFcn', @(btn, e) RunOptimization(app, e));
            app.ExportButton = uibutton(app.LeftPanel, 'push', 'Text', 'Export Excel (Multi-Sheet)', 'Position', [20 95 250 38], 'Enable', 'off', 'ButtonPushedFcn', @(btn, e) ExportToExcel(app, e));

            app.StatusLabel  = uilabel(app.LeftPanel, 'Text', 'Status: Ready', 'Position', [20 20 260 30], 'FontWeight', 'bold');

            % Tab Group
            app.TabGroup     = uitabgroup(app.RightPanel, 'Position', [10 10 630 600]);
            app.CostTab      = uitab(app.TabGroup, 'Title', 'Optimization & Costs');
            app.HydraulicsTab= uitab(app.TabGroup, 'Title', 'Hydraulic Results');

            % Tab 1 Components
            app.UIAxes           = uiaxes(app.CostTab, 'Position', [10 230 600 330]);
            app.UITablePipes     = uitable(app.CostTab, 'Position', [10 20 380 190]);
            app.CostSummaryLabel = uilabel(app.CostTab, 'Text', 'Optimal Cost: $ -', 'Position', [410 100 200 30], 'FontSize', 12, 'FontWeight', 'bold');

            % Tab 2 Components
            app.PressureAxes     = uiaxes(app.HydraulicsTab, 'Position', [10 290 360 270]);
            app.VelocityAxes     = uiaxes(app.HydraulicsTab, 'Position', [10 10 360 270]);
            app.UITableNodes     = uitable(app.HydraulicsTab, 'Position', [380 50 235 510]);
            app.NodeStatusLabel  = uilabel(app.HydraulicsTab, 'Text', 'Min P: - | Max V: -', 'Position', [380 10 235 30], 'FontSize', 11, 'FontWeight', 'bold');
        end
    end

    methods (Access = public)
        function app = WDS_Optimizer_App
            createComponents(app)
        end
    end
end