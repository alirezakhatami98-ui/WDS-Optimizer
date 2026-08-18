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
        
        % Algorithm Inputs
        NSEditField           matlab.ui.control.NumericEditField
        NSEditFieldLabel      matlab.ui.control.Label
        MaxGenEditField       matlab.ui.control.NumericEditField
        MaxGenEditFieldLabel  matlab.ui.control.Label
        
        % Constraint Input Controls
        PminEditField         matlab.ui.control.NumericEditField
        PminEditFieldLabel    matlab.ui.control.Label
        
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
        
        % Tab 2 (Hydraulics)
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
                % Normalizing path separators to avoid escape sequence issues
                fullPath = strrep(fullPath, '\', '/');
        
                if contains(fullPath, ' ')
                    uialert(app.UIFigure, ...
                        'The selected file path contains a space. Please move the folder or file to a path without spaces.', ...
                        'File path error');
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
                uialert(app.UIFigure, 'Please load all input files first!', 'Input Error');
                return;
            end

            app.StatusLabel.Text = 'Status: Running Optimization...';
            app.RunButton.Enable = 'off';
            drawnow;

            try
                % 1. Load Data
                Din  = load(app.DFileStr);
                Cost = load(app.CostFileStr);
                D    = Din * 25.4; % inch to mm

                % --- FIX: Save directly to C:\ to guarantee NO spaces in path ---
                try
                    tempInpPath = 'C:\temp_network.inp';
                    copyfile(app.InpFileStr, tempInpPath, 'f');
                catch
                    % If C:\ is write-protected, save to current MATLAB working directory
                    tempInpPath = fullfile(pwd, 'temp_network.inp');
                    copyfile(app.InpFileStr, tempInpPath, 'f');
                end

                % 2. Open EPANET Engine
                d = epanet(tempInpPath);
                NP = d.getLinkPipeCount();
                NN = d.getNodeCount();

                L = zeros(NP, 1);
                for i = 1:NP
                    L(i) = d.getLinkLength(i);
                end

                % 3. Read Algorithm Params & User Constraints
                Params.NS   = app.NSEditField.Value;
                Params.Pmin = app.PminEditField.Value;
                MaxGen      = app.MaxGenEditField.Value;

                % 4. Execution
                [Score, Position, ~] = app.RunGA(d, D, NP, NN, L, Din, Cost, Params, MaxGen);

                app.BestCost = Score;
                app.OptimalDiameters = Position';

                % 5. Post-Processing Hydraulic Analysis
                d.setLinkDiameter(1:NP, app.OptimalDiameters);
                d.solveCompleteHydraulics();

                P = d.getNodePressure();
                types = d.getNodeType();
                junctions = strcmpi(types, 'JUNCTION');

                % Force Column Vectors (:)
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

                % Update Tab 2 Tables (Nodes)
                numNodes = numel(app.NodePressures);
                NodeIDs = (1:numNodes)';
                PressureStatus = cell(numNodes, 1);
                pMinVal = Params.Pmin;

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
                app.NodeStatusLabel.Text = sprintf('Min Node Pressure: %.2f m (Limit: %.1f m)', minP, pMinVal);

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
            Problem.Cost = Cost; Problem.Pmin = Params.Pmin;

            NS = Params.NS; Pc = 0.8; Pm = 0.03; ND = numel(D);
            Conv = zeros(MaxGen, 1);
            BestCostEver = Inf; BestSolEver = [];

            Pop = randi(ND, NP, NS);
            [cost, viol, feas] = app.evaluate_pop(Pop, Problem);

            for G = 1:MaxGen
                Fitness = app.calculate_fitness(cost, viol);
                SelectedIdx = app.selection_roulette(Fitness, NS);
                MatingPool = Pop(:, SelectedIdx);

                NewPop = MatingPool;
                for i = 1:2:NS-1
                    if rand < Pc
                        cp = randi(NP - 1);
                        NewPop(:, i)   = [MatingPool(1:cp, i); MatingPool(cp+1:end, i+1)];
                        NewPop(:, i+1) = [MatingPool(1:cp, i+1); MatingPool(cp+1:end, i)];
                    end
                end

                for i = 1:NS
                    for j = 1:NP
                        if rand < Pm, NewPop(j, i) = randi(ND); end
                    end
                end

                if ~isempty(BestSolEver), NewPop(:, 1) = BestSolEver; end

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

                Conv(G) = BestCostEver;

                if mod(G, 5) == 0 || G == MaxGen
                    plot(app.UIAxes, 1:G, Conv(1:G), 'LineWidth', 2, 'Color', [0.85 0.32 0.1]);
                    xlabel(app.UIAxes, 'Generation');
                    ylabel(app.UIAxes, 'Best Cost ($)');
                    title(app.UIAxes, sprintf('Convergence (Gen %d/%d)', G, MaxGen));
                    grid(app.UIAxes, 'on');
                    drawnow;
                end
            end

            Score = BestCostEver;
            Position = D(BestSolEver)';
        end

        % --- Export Data to Excel ---
        function ExportToExcel(app, ~)
            [file, path] = uiputfile('*.xlsx', 'Save Comprehensive Results as Excel');
            if ischar(file)
                fullFileName = fullfile(path, file);
                
                % Write Pipes sheet
                writetable(app.UITablePipes.Data, fullFileName, 'Sheet', 'Pipe_Optimization');
                
                % Write Nodes sheet
                writetable(app.UITableNodes.Data, fullFileName, 'Sheet', 'Hydraulic_Nodes');
                
                uialert(app.UIFigure, 'Pipes and Hydraulic Node results exported successfully!', 'Export Success');
            end
        end

        % --- GA Helpers ---
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
            Din = Problem.Din; Cost = Problem.Cost; Pmin = Problem.Pmin;

            d.setLinkDiameter(1:NP, D(ind)');
            d.solveCompleteHydraulics();
            
            P = d.getNodePressure();
            types = d.getNodeType();
            Pj = P(strcmpi(types, 'JUNCTION'));

            % Cost Calculation
            cost = 0;
            for i = 1:NP
                Dmm = Din * 25.4;
                [~, idx] = min(abs(Dmm - D(ind(i))));
                cost = cost + L(i) * Cost(idx);
            end

            % Pressure Constraint Violation
            viol = sum(max(0, Pmin - Pj));
            feas = (viol == 0);
        end
    end

    % Component initialization
    methods (Access = private)

        function createComponents(app)
            % Main Figure
            app.UIFigure = uifigure('Position', [100 100 950 600], 'Name', 'WDS Optimization Toolkit v1.1.1');

            % Panels
            app.LeftPanel  = uipanel(app.UIFigure, 'Title', 'Input Controls & Constraints', 'Position', [10 10 300 580]);
            app.RightPanel = uipanel(app.UIFigure, 'Title', 'Results & Hydraulic Analysis', 'Position', [320 10 620 580]);

            % Left Panel - File Selection
            app.INPButton  = uibutton(app.LeftPanel, 'push', 'Text', 'Load .INP File', 'Position', [20 510 120 28], 'ButtonPushedFcn', @(btn, e) SelectINPFile(app, e));
            app.INPLabel   = uilabel(app.LeftPanel, 'Text', 'No file selected', 'Position', [150 510 130 28]);

            app.DButton    = uibutton(app.LeftPanel, 'push', 'Text', 'Load D.txt', 'Position', [20 470 120 28], 'ButtonPushedFcn', @(btn, e) SelectDFile(app, e));
            app.DLabel     = uilabel(app.LeftPanel, 'Text', 'No file selected', 'Position', [150 470 130 28]);

            app.CostButton = uibutton(app.LeftPanel, 'push', 'Text', 'Load Cost.txt', 'Position', [20 430 120 28], 'ButtonPushedFcn', @(btn, e) SelectCostFile(app, e));
            app.CostLabel  = uilabel(app.LeftPanel, 'Text', 'No file selected', 'Position', [150 430 130 28]);

            % Algorithm Parameters
            app.NSEditFieldLabel = uilabel(app.LeftPanel, 'Text', 'Population (NS):', 'Position', [20 375 130 22]);
            app.NSEditField      = uieditfield(app.LeftPanel, 'numeric', 'Position', [160 375 100 22], 'Value', 100);

            app.MaxGenEditFieldLabel = uilabel(app.LeftPanel, 'Text', 'Max Gen:', 'Position', [20 340 130 22]);
            app.MaxGenEditField      = uieditfield(app.LeftPanel, 'numeric', 'Position', [160 340 100 22], 'Value', 500);

            % Constraints Control
            app.PminEditFieldLabel = uilabel(app.LeftPanel, 'Text', 'Min Pressure (m):', 'Position', [20 290 130 22], 'FontWeight', 'bold');
            app.PminEditField      = uieditfield(app.LeftPanel, 'numeric', 'Position', [160 290 100 22], 'Value', 30.0);

            % Action Buttons
            app.RunButton    = uibutton(app.LeftPanel, 'push', 'Text', 'Run Optimization', 'Position', [20 160 250 42], 'BackgroundColor', [0.1 0.6 0.2], 'FontColor', 'w', 'FontSize', 14, 'FontWeight', 'bold', 'ButtonPushedFcn', @(btn, e) RunOptimization(app, e));
            app.ExportButton = uibutton(app.LeftPanel, 'push', 'Text', 'Export Excel (Multi-Sheet)', 'Position', [20 100 250 38], 'Enable', 'off', 'ButtonPushedFcn', @(btn, e) ExportToExcel(app, e));

            app.StatusLabel  = uilabel(app.LeftPanel, 'Text', 'Status: Ready', 'Position', [20 30 260 30], 'FontWeight', 'bold');

            % Tab Group in Right Panel
            app.TabGroup     = uitabgroup(app.RightPanel, 'Position', [10 10 600 540]);
            app.CostTab      = uitab(app.TabGroup, 'Title', 'Optimization & Costs');
            app.HydraulicsTab= uitab(app.TabGroup, 'Title', 'Hydraulic Results');

            % Tab 1 Components
            app.UIAxes           = uiaxes(app.CostTab, 'Position', [10 200 570 300]);
            app.UITablePipes     = uitable(app.CostTab, 'Position', [10 20 360 160]);
            app.CostSummaryLabel = uilabel(app.CostTab, 'Text', 'Optimal Cost: $ -', 'Position', [390 85 180 30], 'FontSize', 12, 'FontWeight', 'bold');

            % Tab 2 Components
            app.UITableNodes     = uitable(app.HydraulicsTab, 'Position', [10 60 570 440]);
            app.NodeStatusLabel  = uilabel(app.HydraulicsTab, 'Text', 'Min Node Pressure: -', 'Position', [10 15 570 30], 'FontSize', 12, 'FontWeight', 'bold');
        end
    end

    methods (Access = public)
        function app = WDS_Optimizer_App
            createComponents(app)
        end
    end
end