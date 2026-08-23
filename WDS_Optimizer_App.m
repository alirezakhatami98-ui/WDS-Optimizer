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
        
        % Hydraulic & Algorithm Settings
        HeadlossDropDownLabel matlab.ui.control.Label
        HeadlossDropDown     matlab.ui.control.DropDown
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
        BenchmarkButton       matlab.ui.control.Button
        ExportButton          matlab.ui.control.Button
        StatusLabel           matlab.ui.control.Label
        
        % Right Panel Components (Tabbed Layout)
        TabGroup              matlab.ui.container.TabGroup
        CostTab               matlab.ui.container.Tab
        HydraulicsTab         matlab.ui.container.Tab
        BenchmarkTab          matlab.ui.container.Tab
        
        % Tab 1 (Costs & Convergence)
        UIAxes                matlab.ui.control.UIAxes
        UITablePipes          matlab.ui.control.Table
        CostSummaryLabel      matlab.ui.control.Label
        
        % Tab 2 (Hydraulic Plots & Tables)
        PressureAxes          matlab.ui.control.UIAxes
        VelocityAxes          matlab.ui.control.UIAxes
        UITableNodes          matlab.ui.control.Table
        NodeStatusLabel       matlab.ui.control.Label

        % Tab 3 (Benchmark Comparison)
        BenchmarkAxes         matlab.ui.control.UIAxes
        UITableBenchmark      matlab.ui.control.Table
        
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
                fullPath = strrep(fullfile(path, file), '\', '/');
                if contains(fullPath, ' ')
                    uialert(app.UIFigure, 'Path contains spaces. Move file to a folder without spaces.', 'File Path Error');
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

        function UpdateInpHeadlossFormula(~, inpFilePath, selectedFormula)
            switch selectedFormula
                case 'Hazen-Williams (HW)'
                    codeStr = 'H-W';
                case 'Darcy-Weisbach (DW)'
                    codeStr = 'D-W';
                case 'Manning (CM)'
                    codeStr = 'C-M';
            end

            % Read lines from temporary INP file
            fid = fopen(inpFilePath, 'r');
            if fid == -1, return; end
            lines = {};
            while ~feof(fid)
                lines{end+1} = fgetl(fid); %#ok<AGROW>
            end
            fclose(fid);

            % Replace or append HEADLOSS option
            found = false;
            for i = 1:numel(lines)
                if startsWith(strtrim(lines{i}), 'HEADLOSS', 'IgnoreCase', true)
                    lines{i} = sprintf(' HEADLOSS           %s', codeStr);
                    found = true;
                    break;
                end
            end

            if ~found
                % Insert HEADLOSS under [OPTIONS] section
                for i = 1:numel(lines)
                    if contains(lines{i}, '[OPTIONS]', 'IgnoreCase', true)
                        lines = [lines(1:i); {sprintf(' HEADLOSS           %s', codeStr)}; lines(i+1:end)];
                        break;
                    end
                end
            end

            % Write modified content back to temporary INP file
            fid = fopen(inpFilePath, 'w');
            for i = 1:numel(lines)
                fprintf(fid, '%s\n', lines{i});
            end
            fclose(fid);
        end

        % --- Main Optimization Routing ---
        function RunOptimization(app, ~)
            if isempty(app.InpFileStr) || isempty(app.DFileStr) || isempty(app.CostFileStr)
                uialert(app.UIFigure, 'Please load all required input files first!', 'Input Error');
                return;
            end

            app.StatusLabel.Text = 'Status: Running Optimization...';
            app.RunButton.Enable = 'off';
            app.BenchmarkButton.Enable = 'off';
            drawnow;

            try
                [d, Din, Cost, D, NP, L, InitialD, Params, MaxGen] = app.PrepareEnvironment();
                
                SelectedAlg = app.AlgorithmDropDown.Value;
                if strcmp(SelectedAlg, 'Genetic Algorithm (GA)')
                    [Score, Position, ~] = app.RunGA(d, D, NP, L, Din, Cost, Params, MaxGen);
                else
                    [Score, Position, ~] = app.RunPSO(d, D, NP, L, Din, Cost, Params, MaxGen);
                end

                app.UpdateGUIResults(d, Score, Position, NP, Params);
                d.unload();

                app.StatusLabel.Text = 'Status: Completed Successfully!';
                app.ExportButton.Enable = 'on';
            catch ME
                app.StatusLabel.Text = 'Status: Error occurred!';
                uialert(app.UIFigure, ME.message, 'Execution Error');
            end

            app.RunButton.Enable = 'on';
            app.BenchmarkButton.Enable = 'on';
        end

        % --- Benchmark Routine (GA vs PSO) ---
        function RunBenchmark(app, ~)
            if isempty(app.InpFileStr) || isempty(app.DFileStr) || isempty(app.CostFileStr)
                uialert(app.UIFigure, 'Please load all required input files first!', 'Input Error');
                return;
            end

            app.StatusLabel.Text = 'Status: Running GA vs PSO Benchmark...';
            app.RunButton.Enable = 'off';
            app.BenchmarkButton.Enable = 'off';
            drawnow;

            try
                [d, Din, Cost, D, NP, L, InitialD, Params, MaxGen] = app.PrepareEnvironment();

                % Run GA
                tGA_start = tic;
                [ScoreGA, PositionGA, ConvGA] = app.RunGA(d, D, NP, L, Din, Cost, Params, MaxGen);
                tGA = toc(tGA_start);

                % Get GA Hydraulics
                d.setLinkDiameter(1:NP, PositionGA);
                d.solveCompleteHydraulics();
                P_GA = d.getNodePressure();
                Pj_GA = P_GA(strcmpi(d.getNodeType(), 'JUNCTION'));
                V_GA = abs(d.getLinkVelocity());

                % Run PSO
                tPSO_start = tic;
                [ScorePSO, PositionPSO, ConvPSO] = app.RunPSO(d, D, NP, L, Din, Cost, Params, MaxGen);
                tPSO = toc(tPSO_start);

                % Get PSO Hydraulics
                d.setLinkDiameter(1:NP, PositionPSO);
                d.solveCompleteHydraulics();
                P_PSO = d.getNodePressure();
                Pj_PSO = P_PSO(strcmpi(d.getNodeType(), 'JUNCTION'));
                V_PSO = abs(d.getLinkVelocity());

                d.unload();

                % Plot Dual Convergence in Benchmark Tab
                plot(app.BenchmarkAxes, 1:MaxGen, ConvGA, '-r', 'LineWidth', 2, 'DisplayName', 'GA');
                hold(app.BenchmarkAxes, 'on');
                plot(app.BenchmarkAxes, 1:MaxGen, ConvPSO, '-b', 'LineWidth', 2, 'DisplayName', 'PSO');
                hold(app.BenchmarkAxes, 'off');
                xlabel(app.BenchmarkAxes, 'Iteration / Generation');
                ylabel(app.BenchmarkAxes, 'Best Cost ($)');
                title(app.BenchmarkAxes, 'GA vs. PSO Convergence Speed');
                legend(app.BenchmarkAxes, 'Location', 'northeast');
                grid(app.BenchmarkAxes, 'on');

                % Fill Benchmark Table
                MetricNames = {'Best Cost ($)'; 'Execution Time (s)'; 'Min Pressure (m)'; 'Max Velocity (m/s)'};
                GA_Results = [ScoreGA; tGA; min(Pj_GA); max(V_GA)];
                PSO_Results = [ScorePSO; tPSO; min(Pj_PSO); max(V_PSO)];

                app.UITableBenchmark.Data = table(MetricNames, GA_Results, PSO_Results, ...
                    'VariableNames', {'Metric', 'Genetic_Algorithm', 'Particle_Swarm'});

                app.TabGroup.SelectedTab = app.BenchmarkTab;
                app.StatusLabel.Text = 'Status: Benchmark Complete!';
            catch ME
                app.StatusLabel.Text = 'Status: Benchmark Error!';
                uialert(app.UIFigure, ME.message, 'Execution Error');
            end

            app.RunButton.Enable = 'on';
            app.BenchmarkButton.Enable = 'on';
        end

        % --- Environment Setup Helper ---
        function [d, Din, Cost, D, NP, L, InitialD, Params, MaxGen] = PrepareEnvironment(app)
            Din  = load(app.DFileStr);
            Cost = load(app.CostFileStr);
            D    = Din * 25.4;

            try
                tempInpPath = 'C:\temp_network.inp';
                copyfile(app.InpFileStr, tempInpPath, 'f');
            catch
                tempInpPath = fullfile(pwd, 'temp_network.inp');
                copyfile(app.InpFileStr, tempInpPath, 'f');
            end

            % 1. Update Headloss Formula directly inside the INP text file
            app.UpdateInpHeadlossFormula(tempInpPath, app.HeadlossDropDown.Value);

            % 2. Load the updated INP file in EPANET
            d = epanet(tempInpPath);

            NP = d.getLinkPipeCount();
            L = zeros(NP, 1);
            InitialD = zeros(NP, 1);
            for i = 1:NP
                L(i) = d.getLinkLength(i);
                InitialD(i) = d.getLinkDiameter(i);
            end

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

            Params.NS   = app.NSEditField.Value;
            Params.Pmin = app.PminEditField.Value;
            Params.Vmax = app.VmaxEditField.Value;
            Params.FixedPipes = fixedPipes;
            Params.VariablePipes = setdiff(1:NP, fixedPipes);
            Params.InitialD = InitialD;
            MaxGen = app.MaxGenEditField.Value;
        end

        % --- Results Updater ---
        function UpdateGUIResults(app, d, Score, Position, NP, Params)
            app.BestCost = Score;
            app.OptimalDiameters = Position';

            d.setLinkDiameter(1:NP, app.OptimalDiameters);
            d.solveCompleteHydraulics();

            P = d.getNodePressure();
            junctions = strcmpi(d.getNodeType(), 'JUNCTION');
            app.NodePressures = P(junctions);
            app.PipeVelocities = abs(d.getLinkVelocity());

            % Tab 1 Updates
            app.UITablePipes.Data = table((1:NP)', app.OptimalDiameters(:), app.PipeVelocities(:), ...
                'VariableNames', {'Pipe_ID', 'Diameter_mm', 'Velocity_m_s'});
            app.CostSummaryLabel.Text = sprintf('Optimal Cost: $%.2f', app.BestCost);

            % Tab 2 Updates
            numNodes = numel(app.NodePressures);
            PressureStatus = cell(numNodes, 1);
            for k = 1:numNodes
                if app.NodePressures(k) < Params.Pmin
                    PressureStatus{k} = sprintf('Violation (<%.1fm)', Params.Pmin);
                else
                    PressureStatus{k} = 'Feasible (OK)';
                end
            end
            app.UITableNodes.Data = table((1:numNodes)', app.NodePressures(:), PressureStatus, ...
                'VariableNames', {'Node_ID', 'Pressure_m', 'Status'});

            app.NodeStatusLabel.Text = sprintf('Min P: %.2fm | Max V: %.2fm/s', min(app.NodePressures), max(app.PipeVelocities));

            % Plots
            bar(app.PressureAxes, 1:numNodes, app.NodePressures, 0.6, 'FaceColor', [0 0.45 0.74]);
            yline(app.PressureAxes, Params.Pmin, '--r', sprintf('Pmin (%.1fm)', Params.Pmin), 'LineWidth', 1.5);
            grid(app.PressureAxes, 'on');

            bar(app.VelocityAxes, 1:NP, app.PipeVelocities, 0.6, 'FaceColor', [0.47 0.67 0.19]);
            yline(app.VelocityAxes, Params.Vmax, '--r', sprintf('Vmax (%.1fm/s)', Params.Vmax), 'LineWidth', 1.5);
            grid(app.VelocityAxes, 'on');
        end

        % --- GA Engine ---
        function [Score, Position, Conv] = RunGA(app, d, D, NP, L, Din, Cost, Params, MaxGen)
            Problem.d = d; Problem.D = D; Problem.NP = NP; Problem.L = L; Problem.Din = Din;
            Problem.Cost = Cost; Problem.Pmin = Params.Pmin; Problem.Vmax = Params.Vmax;
            Problem.VariablePipes = Params.VariablePipes; Problem.InitialD = Params.InitialD;

            NS = Params.NS; Pc = 0.8; Pm = 0.03; ND = numel(D);
            NVar = numel(Problem.VariablePipes);
            Conv = zeros(MaxGen, 1);
            BestCostEver = Inf; BestSolEver = []; BestViolEver = Inf; BestUnfeasibleSol = []; BestUnfeasibleCost = Inf;

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

                if ~isempty(BestSolEver), NewPop(:, 1) = BestSolEver;
                elseif ~isempty(BestUnfeasibleSol), NewPop(:, 1) = BestUnfeasibleSol; end

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

                Conv(G) = ternary(~isempty(BestSolEver), BestCostEver, BestUnfeasibleCost);

                if mod(G, 5) == 0 || G == MaxGen
                    plot(app.UIAxes, 1:G, Conv(1:G), 'LineWidth', 2, 'Color', [0.85 0.32 0.1]);
                    xlabel(app.UIAxes, 'Generation'); ylabel(app.UIAxes, 'Best Cost ($)');
                    title(app.UIAxes, sprintf('GA Convergence (Gen %d/%d)', G, MaxGen));
                    grid(app.UIAxes, 'on'); drawnow;
                end
            end

            if isempty(BestSolEver)
                BestSolEver = BestUnfeasibleSol;
                BestCostEver = BestUnfeasibleCost;
            end

            Score = BestCostEver;
            FullDiameters = Problem.InitialD;
            FullDiameters(Problem.VariablePipes) = D(BestSolEver);
            Position = FullDiameters';
        end

        % --- PSO Engine ---
        function [Score, Position, Conv] = RunPSO(app, d, D, NP, L, Din, Cost, Params, MaxGen)
            Problem.d = d; Problem.D = D; Problem.NP = NP; Problem.L = L; Problem.Din = Din;
            Problem.Cost = Cost; Problem.Pmin = Params.Pmin; Problem.Vmax = Params.Vmax;
            Problem.VariablePipes = Params.VariablePipes; Problem.InitialD = Params.InitialD;

            N = Params.NS; ND = numel(D); NVar = numel(Problem.VariablePipes);
            w = 0.7; c1 = 1.5; c2 = 1.5;

            X = randi(ND, NVar, N); V = zeros(NVar, N);
            PBestX = X; PBestCost = Inf(1, N); PBestViol = Inf(1, N);
            GBestX = []; GBestCost = Inf; GBestViol = Inf;
            Conv = zeros(MaxGen, 1);

            for G = 1:MaxGen
                X_discrete = round(X); X_discrete = max(1, min(ND, X_discrete));
                [cost, viol, feas] = app.evaluate_pop(X_discrete, Problem);

                for i = 1:N
                    if (feas(i) && cost(i) < PBestCost(i)) || (~feas(i) && viol(i) < PBestViol(i))
                        PBestCost(i) = cost(i); PBestViol(i) = viol(i); PBestX(:, i) = X_discrete(:, i);
                    end
                    if (feas(i) && cost(i) < GBestCost) || (~feas(i) && viol(i) < GBestViol)
                        GBestCost = cost(i); GBestViol = viol(i); GBestX = X_discrete(:, i);
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
                    xlabel(app.UIAxes, 'Iteration'); ylabel(app.UIAxes, 'Best Cost ($)');
                    title(app.UIAxes, sprintf('PSO Convergence (Iter %d/%d)', G, MaxGen));
                    grid(app.UIAxes, 'on'); drawnow;
                end
            end

            Score = GBestCost;
            FullDiameters = Problem.InitialD;
            FullDiameters(Problem.VariablePipes) = D(GBestX);
            Position = FullDiameters';
        end

        % --- Export Excel ---
        function ExportToExcel(app, ~)
            [file, path] = uiputfile('*.xlsx', 'Save Comprehensive Results as Excel');
            if ischar(file)
                fullFileName = fullfile(path, file);
                writetable(app.UITablePipes.Data, fullFileName, 'Sheet', 'Pipe_Optimization');
                writetable(app.UITableNodes.Data, fullFileName, 'Sheet', 'Hydraulic_Nodes');
                if ~isempty(app.UITableBenchmark.Data)
                    writetable(app.UITableBenchmark.Data, fullFileName, 'Sheet', 'Algorithm_Benchmark');
                end
                uialert(app.UIFigure, 'Results exported successfully!', 'Export Success');
            end
        end

        % --- Evaluation Helpers ---
        function Fitness = calculate_fitness(~, cost, viol)
            Fitness = 1 ./ (cost + 2e6 * (viol .^ 2) + 1e-6);
        end

        function idx = selection_roulette(~, Fitness, NS)
            prob = Fitness / sum(Fitness); cum_prob = cumsum(prob); idx = zeros(1, NS);
            for i = 1:NS, idx(i) = find(rand <= cum_prob, 1, 'first'); end
        end

        function [cost, viol, feas] = evaluate_pop(app, Pop, Problem)
            NS = size(Pop, 2); cost = zeros(NS, 1); viol = zeros(NS, 1); feas = false(NS, 1);
            for i = 1:NS, [cost(i), viol(i), feas(i)] = app.evaluate_ind(Pop(:, i), Problem); end
        end

        function [cost, viol, feas] = evaluate_ind(~, ind, Problem)
            d = Problem.d; D = Problem.D; NP = Problem.NP; L = Problem.L;
            Din = Problem.Din; Cost = Problem.Cost; Pmin = Problem.Pmin; Vmax = Problem.Vmax;
            
            FullD = Problem.InitialD;
            FullD(Problem.VariablePipes) = D(ind);

            d.setLinkDiameter(1:NP, FullD');
            d.solveCompleteHydraulics();
            
            P = d.getNodePressure();
            Pj = P(strcmpi(d.getNodeType(), 'JUNCTION'));
            Vpipes = abs(d.getLinkVelocity());

            cost = 0;
            for i = Problem.VariablePipes
                [~, idx] = min(abs((Din * 25.4) - FullD(i)));
                cost = cost + L(i) * Cost(idx);
            end

            viol = sum(max(0, Pmin - Pj)) + sum(max(0, Vpipes - Vmax));
            feas = (viol == 0);
        end
    end

    % Component Initialization
    methods (Access = private)
        function createComponents(app)
            app.UIFigure = uifigure('Position', [100 100 1020 680], 'Name', 'WDS Optimization Toolkit v1.6.0');

            app.LeftPanel  = uipanel(app.UIFigure, 'Title', 'Input Controls & Constraints', 'Position', [10 10 310 660]);
            app.RightPanel = uipanel(app.UIFigure, 'Title', 'Results & Benchmark Analysis', 'Position', [330 10 680 660]);

            % File Loading
            app.INPButton  = uibutton(app.LeftPanel, 'push', 'Text', 'Load .INP File', 'Position', [20 590 120 28], 'ButtonPushedFcn', @(btn, e) SelectINPFile(app, e));
            app.INPLabel   = uilabel(app.LeftPanel, 'Text', 'No file selected', 'Position', [150 590 140 28]);

            app.DButton    = uibutton(app.LeftPanel, 'push', 'Text', 'Load D.txt', 'Position', [20 550 120 28], 'ButtonPushedFcn', @(btn, e) SelectDFile(app, e));
            app.DLabel     = uilabel(app.LeftPanel, 'Text', 'No file selected', 'Position', [150 550 140 28]);

            app.CostButton = uibutton(app.LeftPanel, 'push', 'Text', 'Load Cost.txt', 'Position', [20 510 120 28], 'ButtonPushedFcn', @(btn, e) SelectCostFile(app, e));
            app.CostLabel  = uilabel(app.LeftPanel, 'Text', 'No file selected', 'Position', [150 510 140 28]);

            % Hydraulic Settings
            app.HeadlossDropDownLabel = uilabel(app.LeftPanel, 'Text', 'Headloss Formula:', 'Position', [20 460 120 22], 'FontWeight', 'bold');
            app.HeadlossDropDown      = uidropdown(app.LeftPanel, 'Position', [140 460 150 22], 'Items', {'Hazen-Williams (HW)', 'Darcy-Weisbach (DW)', 'Manning (CM)'});

            % Algorithm Settings
            app.AlgorithmDropDownLabel = uilabel(app.LeftPanel, 'Text', 'Algorithm:', 'Position', [20 420 100 22], 'FontWeight', 'bold');
            app.AlgorithmDropDown      = uidropdown(app.LeftPanel, 'Position', [140 420 150 22], 'Items', {'Genetic Algorithm (GA)', 'Particle Swarm (PSO)'});

            app.NSEditFieldLabel = uilabel(app.LeftPanel, 'Text', 'Population / Swarm:', 'Position', [20 380 130 22]);
            app.NSEditField      = uieditfield(app.LeftPanel, 'numeric', 'Position', [160 380 130 22], 'Value', 100);

            app.MaxGenEditFieldLabel = uilabel(app.LeftPanel, 'Text', 'Max Gen / Iter:', 'Position', [20 345 130 22]);
            app.MaxGenEditField      = uieditfield(app.LeftPanel, 'numeric', 'Position', [160 345 130 22], 'Value', 500);

            % Constraints Controls
            app.PminEditFieldLabel = uilabel(app.LeftPanel, 'Text', 'Min Pressure (m):', 'Position', [20 295 130 22], 'FontWeight', 'bold');
            app.PminEditField      = uieditfield(app.LeftPanel, 'numeric', 'Position', [160 295 130 22], 'Value', 30.0);

            app.VmaxEditFieldLabel = uilabel(app.LeftPanel, 'Text', 'Max Velocity (m/s):', 'Position', [20 260 130 22], 'FontWeight', 'bold');
            app.VmaxEditField      = uieditfield(app.LeftPanel, 'numeric', 'Position', [160 260 130 22], 'Value', 2.5);

            % Fixed Pipes
            app.FixedPipesLabel     = uilabel(app.LeftPanel, 'Text', 'Fixed Pipe IDs (e.g. 1, 3):', 'Position', [20 215 150 22], 'FontWeight', 'bold');
            app.FixedPipesEditField = uieditfield(app.LeftPanel, 'text', 'Position', [170 215 120 22], 'Value', '');

            % Buttons
            app.RunButton       = uibutton(app.LeftPanel, 'push', 'Text', 'Run Single Optimization', 'Position', [20 150 270 38], 'BackgroundColor', [0.1 0.6 0.2], 'FontColor', 'w', 'FontSize', 12, 'FontWeight', 'bold', 'ButtonPushedFcn', @(btn, e) RunOptimization(app, e));
            app.BenchmarkButton = uibutton(app.LeftPanel, 'push', 'Text', 'Run GA vs PSO Benchmark', 'Position', [20 105 270 38], 'BackgroundColor', [0.85 0.32 0.1], 'FontColor', 'w', 'FontSize', 12, 'FontWeight', 'bold', 'ButtonPushedFcn', @(btn, e) RunBenchmark(app, e));
            app.ExportButton    = uibutton(app.LeftPanel, 'push', 'Text', 'Export Excel (Multi-Sheet)', 'Position', [20 60 270 35], 'Enable', 'off', 'ButtonPushedFcn', @(btn, e) ExportToExcel(app, e));

            app.StatusLabel     = uilabel(app.LeftPanel, 'Text', 'Status: Ready', 'Position', [20 15 270 30], 'FontWeight', 'bold');

            % Tab Group
            app.TabGroup     = uitabgroup(app.RightPanel, 'Position', [10 10 660 620]);
            app.CostTab      = uitab(app.TabGroup, 'Title', 'Optimization & Costs');
            app.HydraulicsTab= uitab(app.TabGroup, 'Title', 'Hydraulic Results');
            app.BenchmarkTab = uitab(app.TabGroup, 'Title', 'GA vs PSO Benchmark');

            % Tab 1
            app.UIAxes           = uiaxes(app.CostTab, 'Position', [10 240 630 330]);
            app.UITablePipes     = uitable(app.CostTab, 'Position', [10 20 400 200]);
            app.CostSummaryLabel = uilabel(app.CostTab, 'Text', 'Optimal Cost: $ -', 'Position', [430 110 200 30], 'FontSize', 12, 'FontWeight', 'bold');

            % Tab 2
            app.PressureAxes     = uiaxes(app.HydraulicsTab, 'Position', [10 300 380 280]);
            app.VelocityAxes     = uiaxes(app.HydraulicsTab, 'Position', [10 10 380 280]);
            app.UITableNodes     = uitable(app.HydraulicsTab, 'Position', [400 50 245 530]);
            app.NodeStatusLabel  = uilabel(app.HydraulicsTab, 'Text', 'Min P: - | Max V: -', 'Position', [400 10 245 30], 'FontSize', 11, 'FontWeight', 'bold');

            % Tab 3 (Benchmark)
            app.BenchmarkAxes    = uiaxes(app.BenchmarkTab, 'Position', [10 220 630 350]);
            app.UITableBenchmark = uitable(app.BenchmarkTab, 'Position', [10 20 630 180]);
        end
    end

    methods (Access = public)
        function app = WDS_Optimizer_App
            createComponents(app)
        end
    end
end

function val = ternary(cond, trueVal, falseVal)
    if cond, val = trueVal; else, val = falseVal; end
end