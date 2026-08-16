classdef WDS_Optimizer_App < matlab.apps.AppBase

    % Properties corresponding to UI components
    properties (Access = private)
        UIFigure              matlab.ui.Figure
        LeftPanel             matlab.ui.container.Panel
        RightPanel            matlab.ui.container.Panel
        
        % Left Panel Components (Inputs)
        INPButton             matlab.ui.control.Button
        INPLabel              matlab.ui.control.Label
        DButton               matlab.ui.control.Button
        DLabel                matlab.ui.control.Label
        CostButton            matlab.ui.control.Button
        CostLabel             matlab.ui.control.Label
        
        NSEditField           matlab.ui.control.NumericEditField
        NSEditFieldLabel      matlab.ui.control.Label
        MaxGenEditField       matlab.ui.control.NumericEditField
        MaxGenEditFieldLabel  matlab.ui.control.Label
        
        RunButton             matlab.ui.control.Button
        ExportButton          matlab.ui.control.Button
        
        % Right Panel Components (Outputs)
        UIAxes                matlab.ui.control.UIAxes
        UITable               matlab.ui.control.Table
        CostSummaryLabel      matlab.ui.control.Label
        StatusLabel           matlab.ui.control.Label
        
        % Internal Data Storage
        InpFileStr
        DFileStr
        CostFileStr
        OptimalDiameters
        BestCost
    end

    methods (Access = private)

        % --- Button Push Functions ---
        function SelectINPFile(app, ~)
            [file, path] = uigetfile('*.inp', 'Select EPANET .inp File');
            if ischar(file)
                app.InpFileStr = fullfile(path, file);
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

        % --- Main Run Optimization Event ---
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

                % 2. Open EPANET Engine
                d = epanet(app.InpFileStr);
                NP = d.getLinkPipeCount();
                NN = d.getNodeCount();

                L = zeros(NP, 1);
                for i = 1:NP
                    L(i) = d.getLinkLength(i);
                end

                % 3. Algorithm Parameters
                Params.NS = app.NSEditField.Value;
                MaxGen    = app.MaxGenEditField.Value;

                % 4. Optimization Engine Execution
                [Score, Position, Conv] = app.RunGA(d, D, NP, NN, L, Din, Cost, Params, MaxGen);

                % 5. Save & Display Results
                app.BestCost = Score;
                app.OptimalDiameters = Position';

                d.unload();

                % Update Table
                PipesList = (1:NP)';
                TableData = table(PipesList, app.OptimalDiameters, 'VariableNames', {'Pipe_ID', 'Diameter_mm'});
                app.UITable.Data = TableData;

                % Update Labels
                app.CostSummaryLabel.Text = sprintf('Optimal Network Cost: $%.2f', app.BestCost);
                app.StatusLabel.Text = 'Status: Optimization Completed Successfully!';
                app.ExportButton.Enable = 'on';

            catch ME
                app.StatusLabel.Text = 'Status: Error occurred!';
                uialert(app.UIFigure, ME.message, 'Execution Error');
            end

            app.RunButton.Enable = 'on';
        end

        % --- GA Algorithm Core inside App ---
        function [Score, Position, Conv] = RunGA(app, d, D, NP, NN, L, Din, Cost, Params, MaxGen)
            Problem.d = d; Problem.D = D; Problem.NP = NP;
            Problem.NN = NN; Problem.L = L; Problem.Din = Din;
            Problem.Cost = Cost; Problem.Pmin = 30;

            NS = Params.NS; Pc = 0.8; Pm = 0.03; ND = numel(D);
            Conv = zeros(MaxGen, 1);
            BestCostEver = Inf; BestSolEver = [];

            Pop = randi(ND, NP, NS);
            [cost, viol, feas] = app.evaluate_pop(Pop, Problem);

            for G = 1:MaxGen
                % Selection
                Fitness = app.calculate_fitness(cost, viol);
                SelectedIdx = app.selection_roulette(Fitness, NS);
                MatingPool = Pop(:, SelectedIdx);

                % Crossover
                NewPop = MatingPool;
                for i = 1:2:NS-1
                    if rand < Pc
                        cp = randi(NP - 1);
                        NewPop(:, i)   = [MatingPool(1:cp, i); MatingPool(cp+1:end, i+1)];
                        NewPop(:, i+1) = [MatingPool(1:cp, i+1); MatingPool(cp+1:end, i)];
                    end
                end

                % Mutation
                for i = 1:NS
                    for j = 1:NP
                        if rand < Pm, NewPop(j, i) = randi(ND); end
                    end
                end

                % Elitism
                if ~isempty(BestSolEver), NewPop(:, 1) = BestSolEver; end

                Pop = NewPop;
                [cost, viol, feas] = app.evaluate_pop(Pop, Problem);

                % Tracking
                feasible_idx = find(feas);
                if ~isempty(feasible_idx)
                    [min_c, k] = min(cost(feasible_idx));
                    if min_c < BestCostEver
                        BestCostEver = min_c;
                        BestSolEver  = Pop(:, feasible_idx(k));
                    end
                end

                Conv(G) = BestCostEver;

                % Live Plot Update
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

        % --- Export Results to Excel ---
        function ExportToExcel(app, ~)
            [file, path] = uiputfile('*.xlsx', 'Save Results as Excel');
            if ischar(file)
                fullFileName = fullfile(path, file);
                T = app.UITable.Data;
                writetable(T, fullFileName);
                uialert(app.UIFigure, 'Results exported successfully!', 'Export Success');
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

            cost = 0;
            for i = 1:NP
                Dmm = Din * 25.4;
                [~, idx] = min(abs(Dmm - D(ind(i))));
                cost = cost + L(i) * Cost(idx);
            end

            viol = sum(max(0, Pmin - Pj));
            feas = (viol == 0);
        end
    end

    % Component initialization
    methods (Access = private)

        function createComponents(app)
            % Main Figure
            app.UIFigure = uifigure('Position', [100 100 900 550], 'Name', 'WDS Optimization Toolkit v1.0');

            % Panels
            app.LeftPanel  = uipanel(app.UIFigure, 'Title', 'Input Controls', 'Position', [10 10 300 530]);
            app.RightPanel = uipanel(app.UIFigure, 'Title', 'Results & Visualization', 'Position', [320 10 570 530]);

            % Left Panel: Files Selection
            app.INPButton  = uibutton(app.LeftPanel, 'push', 'Text', 'Load .INP File', 'Position', [20 450 120 30], 'ButtonPushedFcn', @(btn, e) SelectINPFile(app, e));
            app.INPLabel   = uilabel(app.LeftPanel, 'Text', 'No file selected', 'Position', [150 450 130 30]);

            app.DButton    = uibutton(app.LeftPanel, 'push', 'Text', 'Load D.txt', 'Position', [20 400 120 30], 'ButtonPushedFcn', @(btn, e) SelectDFile(app, e));
            app.DLabel     = uilabel(app.LeftPanel, 'Text', 'No file selected', 'Position', [150 400 130 30]);

            app.CostButton = uibutton(app.LeftPanel, 'push', 'Text', 'Load Cost.txt', 'Position', [20 350 120 30], 'ButtonPushedFcn', @(btn, e) SelectCostFile(app, e));
            app.CostLabel  = uilabel(app.LeftPanel, 'Text', 'No file selected', 'Position', [150 350 130 30]);

            % Left Panel: GA Parameters
            app.NSEditFieldLabel = uilabel(app.LeftPanel, 'Text', 'Population Size (NS):', 'Position', [20 280 140 22]);
            app.NSEditField      = uieditfield(app.LeftPanel, 'numeric', 'Position', [160 280 100 22], 'Value', 100);

            app.MaxGenEditFieldLabel = uilabel(app.LeftPanel, 'Text', 'Max Generations:', 'Position', [20 240 140 22]);
            app.MaxGenEditField      = uieditfield(app.LeftPanel, 'numeric', 'Position', [160 240 100 22], 'Value', 500);

            % Left Panel: Action Buttons
            app.RunButton    = uibutton(app.LeftPanel, 'push', 'Text', 'Run Optimization', 'Position', [20 140 240 40], 'BackgroundColor', [0.1 0.6 0.2], 'FontColor', 'w', 'FontSize', 14, 'FontWeight', 'bold', 'ButtonPushedFcn', @(btn, e) RunOptimization(app, e));
            app.ExportButton = uibutton(app.LeftPanel, 'push', 'Text', 'Export to Excel', 'Position', [20 80 240 35], 'Enable', 'off', 'ButtonPushedFcn', @(btn, e) ExportToExcel(app, e));

            app.StatusLabel  = uilabel(app.LeftPanel, 'Text', 'Status: Ready', 'Position', [20 20 250 30], 'FontWeight', 'bold');

            % Right Panel: Plots & Table
            app.UIAxes           = uiaxes(app.RightPanel, 'Position', [20 200 530 290]);
            app.UITable          = uitable(app.RightPanel, 'Position', [20 20 300 160]);
            app.CostSummaryLabel = uilabel(app.RightPanel, 'Text', 'Optimal Network Cost: $ -', 'Position', [340 100 210 40], 'FontSize', 12, 'FontWeight', 'bold');
        end
    end

    methods (Access = public)
        function app = WDS_Optimizer_App
            createComponents(app)
        end
    end
end