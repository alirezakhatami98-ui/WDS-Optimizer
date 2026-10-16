classdef WDS_Optimizer_App < matlab.apps.AppBase

    % Properties corresponding to UI components
    properties (Access = private)
        UIFigure              matlab.ui.Figure
        LeftPanel             matlab.ui.container.Panel

        % Input files
        INPButton             matlab.ui.control.Button
        INPLabel              matlab.ui.control.Label
        DButton               matlab.ui.control.Button
        DLabel                matlab.ui.control.Label
        CostButton            matlab.ui.control.Button
        CostLabel             matlab.ui.control.Label

        % Hydraulic & algorithm size settings
        HeadlossDropDownLabel matlab.ui.control.Label
        HeadlossDropDown      matlab.ui.control.DropDown
        NSEditField           matlab.ui.control.NumericEditField
        NSEditFieldLabel      matlab.ui.control.Label
        MaxGenEditField       matlab.ui.control.NumericEditField
        MaxGenEditFieldLabel  matlab.ui.control.Label

        % Constraints
        PminEditField         matlab.ui.control.NumericEditField
        PminEditFieldLabel    matlab.ui.control.Label
        VmaxEditField         matlab.ui.control.NumericEditField
        VmaxEditFieldLabel    matlab.ui.control.Label
        FixedPipesEditField   matlab.ui.control.EditField
        FixedPipesLabel       matlab.ui.control.Label

        % Experiment controls
        ExperimentSettingsButton matlab.ui.control.Button
        ExperimentSummaryLabel   matlab.ui.control.Label
        RunButton             matlab.ui.control.Button
        ExportButton          matlab.ui.control.Button
        StatusLabel           matlab.ui.control.Label

        % Right side (tabs)
        TabGroup              matlab.ui.container.TabGroup
        SummaryTab            matlab.ui.container.Tab
        CostTab               matlab.ui.container.Tab
        HydraulicsTab         matlab.ui.container.Tab
        RunsTab               matlab.ui.container.Tab

        % Tab: Experiment Summary
        UITableStats          matlab.ui.control.Table
        ConvAxes              matlab.ui.control.UIAxes
        BoxAxes               matlab.ui.control.UIAxes

        % Tab: Best Design
        UIAxes                matlab.ui.control.UIAxes
        UITablePipes          matlab.ui.control.Table
        CostSummaryLabel      matlab.ui.control.Label

        % Tab: Hydraulic Results
        PressureAxes          matlab.ui.control.UIAxes
        VelocityAxes          matlab.ui.control.UIAxes
        UITableNodes          matlab.ui.control.Table
        NodeStatusLabel       matlab.ui.control.Label

        % Tab: All Runs
        UITableRuns           matlab.ui.control.Table

        % Internal data storage
        InpFileStr
        DFileStr
        CostFileStr
        OptimalDiameters
        BestCost
        NodePressures
        PipeVelocities
        ExperimentResult

        % Experiment settings window
        ExperimentSettingsFigure
        GASelectCheckBox
        PSOSelectCheckBox
        NumberOfRunsEditField
        ExperimentSeedEditField
        CacheModeDropDown
        GAPcEditField
        GAPmEditField
        PSOwEditField
        PSOc1EditField
        PSOc2EditField
        ParallelCheckBox
        NumWorkersEditField
        ExperimentSettings

        % Units
        DUnitDropDown         matlab.ui.control.DropDown
        NetworkUnitsLabel     matlab.ui.control.Label
        NetworkUnits
        ResultUnits
    end

    methods (Access = private)

        % --- File Selection Functions ---
        function SelectINPFile(app, ~)
            [file, path] = uigetfile('*.inp', 'Select EPANET .inp File');
            if ischar(file)
                app.InpFileStr = fullfile(path, file);
                app.INPLabel.Text = file;
                app.RefreshNetworkUnits();
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

        % --- Detect network units and update the unit-dependent labels ---
        function RefreshNetworkUnits(app)

            app.StatusLabel.Text = 'Status: Reading network units...';
            drawnow;

            try
                app.NetworkUnits = detectNetworkUnitsFromFile(app.InpFileStr);
                app.ApplyUnitLabels();
                app.StatusLabel.Text = 'Status: Ready';
            catch ME
                app.NetworkUnits = [];
                app.ApplyUnitLabels();
                app.StatusLabel.Text = 'Status: Could not read network units';
                uialert(app.UIFigure, ME.message, 'Network Units Error');
            end

        end

        function ApplyUnitLabels(app)

            U = app.NetworkUnits;

            if isempty(U)
                app.PminEditFieldLabel.Text = 'Min Pressure:';
                app.VmaxEditFieldLabel.Text = 'Max Velocity:';
                app.NetworkUnitsLabel.Text = 'Network units: load an .INP file.';
                return;
            end

            app.PminEditFieldLabel.Text = ...
                sprintf('Min Pressure (%s):', U.PressureUnit);

            app.VmaxEditFieldLabel.Text = ...
                sprintf('Max Velocity (%s):', U.VelocityUnit);

            app.NetworkUnitsLabel.Text = sprintf( ...
                ['Network: %s flow (%s system). Pipe diameter in %s, ', ...
                 'length in %s. Cost.txt = cost per %s of pipe.'], ...
                U.FlowUnit, U.System, U.DiameterUnit, ...
                U.LengthUnit, U.LengthUnit);

        end

        % --- Main Optimization Routing ---
        function RunOptimization(app, ~)

            if isempty(app.InpFileStr) || ...
               isempty(app.DFileStr) || ...
               isempty(app.CostFileStr)

                uialert( ...
                    app.UIFigure, ...
                    'Please load all required input files first!', ...
                    'Input Error');

                return;
            end

            if isempty(app.ExperimentSettings)

                uialert( ...
                    app.UIFigure, ...
                    ['Please open Experiment Settings, configure the ' ...
                    'experiment, and click Apply before running.'], ...
                    'Experiment Settings Required');

                return;
            end

            app.StatusLabel.Text = 'Status: Running Experiment...';
            app.RunButton.Enable = 'off';
            app.ExportButton.Enable = 'off';
            drawnow;

            dlg = uiprogressdlg(app.UIFigure, ...
                'Title', 'Running Experiment', ...
                'Message', 'Preparing the network and optimization problem...', ...
                'Indeterminate', 'on');

            d = [];
            tempInpPath = '';
            parallelInitialized = false;
            Config = [];

            try

                %% 1. Validate and prepare the optimization problem

                validateOptimizationParameters( ...
                    app.NSEditField.Value, ...
                    app.MaxGenEditField.Value, ...
                    app.PminEditField.Value, ...
                    app.VmaxEditField.Value);

                [d, tempInpPath, Problem, Config] = ...
                    app.PrepareEnvironment();

                %% 2. Apply experiment settings

                Settings = app.ExperimentSettings;

                Config.GA = Settings.GA;
                Config.PSO = Settings.PSO;
                Config.Parallel = Settings.Parallel;

                ExperimentAlgorithms = {};

                if any(strcmp(Settings.Algorithms, ...
                        'Genetic Algorithm (GA)'))
                    ExperimentAlgorithms{end + 1} = 'GA';
                end

                if any(strcmp(Settings.Algorithms, ...
                        'Particle Swarm (PSO)'))
                    ExperimentAlgorithms{end + 1} = 'PSO';
                end

                ExperimentOptions.NumberOfRuns = ...
                    Settings.NumberOfRuns;

                ExperimentOptions.Algorithms = ...
                    ExperimentAlgorithms;

                ExperimentOptions.ExperimentSeed = ...
                    Settings.ExperimentSeed;

                ExperimentOptions.CacheMode = ...
                    Settings.CacheMode;

                %% 3. Initialize parallel hydraulic infrastructure

                if Config.Parallel.Enabled

                    dlg.Message = 'Starting parallel workers...';

                    initializeParallelHydraulics( ...
                        tempInpPath, ...
                        Config.Parallel.NumWorkers);

                    parallelInitialized = true;
                end

                %% 4. Run the experiment

                dlg.Message = sprintf( ...
                    ['Running %s: %d run(s) per algorithm.\n' ...
                    'This may take a while...'], ...
                    strjoin(ExperimentAlgorithms, ' + '), ...
                    ExperimentOptions.NumberOfRuns);

                ExpResult = runExperiment( ...
                    d, Problem, Config, ExperimentOptions);

                dlg.Message = 'Collecting results...';

                %% 5. Collect successful runs

                MaxCandidates = 0;

                for a = 1:numel(ExperimentAlgorithms)

                    Algorithm = ExperimentAlgorithms{a};
                    Runs = ExpResult.Results.(Algorithm).Runs;

                    MaxCandidates = MaxCandidates + numel(Runs);

                end

                CandidateScores = nan(MaxCandidates, 1);
                CandidateFeasible = false(MaxCandidates, 1);
                CandidateAlgorithms = cell(MaxCandidates, 1);
                CandidateRunIndices = zeros(MaxCandidates, 1);

                CandidateCount = 0;

                for a = 1:numel(ExperimentAlgorithms)

                    Algorithm = ExperimentAlgorithms{a};
                    Runs = ExpResult.Results.(Algorithm).Runs;

                    for r = 1:numel(Runs)

                        if ~strcmp(Runs(r).Status, 'Success')
                            continue;
                        end

                        if ~isnumeric(Runs(r).Score) || ...
                           ~isscalar(Runs(r).Score) || ...
                           ~isfinite(Runs(r).Score)
                            continue;
                        end

                        CandidateCount = CandidateCount + 1;

                        CandidateScores(CandidateCount) = Runs(r).Score;
                        CandidateFeasible(CandidateCount) = ...
                            logical(Runs(r).Feasible);

                        CandidateAlgorithms{CandidateCount} = Algorithm;
                        CandidateRunIndices(CandidateCount) = r;

                    end
                end

                CandidateScores = CandidateScores(1:CandidateCount);
                CandidateFeasible = CandidateFeasible(1:CandidateCount);
                CandidateAlgorithms = CandidateAlgorithms(1:CandidateCount);
                CandidateRunIndices = CandidateRunIndices(1:CandidateCount);

                if isempty(CandidateScores)

                    error( ...
                        'WDSOptimizer:NoSuccessfulRuns', ...
                        ['No successful experiment runs are available. ' ...
                        'Check the reported run errors and try again.']);

                end

                %% 6. Select the best available candidate

                FeasibleIndices = find(CandidateFeasible);

                if ~isempty(FeasibleIndices)

                    [~, localIndex] = min( ...
                        CandidateScores(FeasibleIndices));

                    BestCandidateIndex = ...
                        FeasibleIndices(localIndex);

                else

                    [~, BestCandidateIndex] = min(CandidateScores);

                end

                BestAlgorithm = ...
                    CandidateAlgorithms{BestCandidateIndex};

                BestRunIndex = ...
                    CandidateRunIndices(BestCandidateIndex);

                BestRun = ExpResult.Results.( ...
                    BestAlgorithm).Runs(BestRunIndex);

                %% 7. Update the experiment-level tabs and best-run plot

                app.ExperimentResult = ExpResult;

                app.UpdateExperimentSummary( ...
                    ExpResult, BestAlgorithm, BestRunIndex);

                app.PlotBestRunConvergence( ...
                    BestAlgorithm, BestRunIndex, BestRun);

                %% 8. Clean up worker hydraulic resources

                if parallelInitialized

                    cleanupParallelHydraulics();
                    parallelInitialized = false;

                end

                %% 9. Update hydraulic results and check convergence

                Converged = app.UpdateGUIResults( ...
                    d, ...
                    BestRun.Score, ...
                    BestRun.Position, ...
                    Problem, ...
                    BestRun.Feasible);

                cleanupEpanetObject(d);
                d = [];

                cleanupTempInpFiles(tempInpPath);

                %% 10. Report experiment and hydraulic status

                TotalRuns = 0;
                SuccessfulRuns = 0;
                FailedRuns = 0;
                NotStartedRuns = 0;

                for a = 1:numel(ExperimentAlgorithms)

                    Algorithm = ExperimentAlgorithms{a};

                    Runs = ExpResult.Results.(Algorithm).Runs;

                    TotalRuns = TotalRuns + numel(Runs);

                    SuccessfulRuns = SuccessfulRuns + ...
                        sum(strcmp({Runs.Status}, 'Success'));

                    FailedRuns = FailedRuns + ...
                        sum(strcmp({Runs.Status}, 'Failed'));

                    NotStartedRuns = NotStartedRuns + ...
                        sum(strcmp({Runs.Status}, 'NotStarted'));

                end

                if SuccessfulRuns == TotalRuns

                    app.StatusLabel.Text = sprintf( ...
                        'Experiment completed: %d/%d runs succeeded.', ...
                        SuccessfulRuns, TotalRuns);

                else

                    app.StatusLabel.Text = sprintf( ...
                        'Experiment finished: %d/%d succeeded, %d failed, %d not started.', ...
                        SuccessfulRuns, TotalRuns, ...
                        FailedRuns, NotStartedRuns);

                end

                if isvalid(dlg)
                    close(dlg);
                end

                if ~Converged

                    uialert( ...
                        app.UIFigure, ...
                        ['The hydraulic solution for the selected design ', ...
                        'did not converge. Displayed pressures and ', ...
                        'velocities may not be reliable.'], ...
                        'Hydraulic Warning', ...
                        'Icon', 'warning');

                end

                app.ExportButton.Enable = 'on';

            catch ME

                if parallelInitialized || ...
                        (~isempty(Config) && ...
                        isfield(Config, 'Parallel') && ...
                        isfield(Config.Parallel, 'Enabled') && ...
                        Config.Parallel.Enabled)
                    try
                        cleanupParallelHydraulics();
                    catch
                    end
                end

                cleanupEpanetObject(d);
                cleanupTempInpFiles(tempInpPath);

                if isvalid(dlg)
                    close(dlg);
                end

                app.StatusLabel.Text = 'Status: Experiment Error!';

                uialert( ...
                    app.UIFigure, ...
                    ME.message, ...
                    'Experiment Execution Error');

            end

            app.RunButton.Enable = 'on';

        end


        % --- Environment Setup Helper ---
        function [d, tempInpPath, Problem, Config] = PrepareEnvironment(app)

            d = [];
            tempInpPath = '';

            try

                tempInpPath = createTempInpFile(app.InpFileStr);

                % 1. Update Headloss Formula directly inside the INP text file
                UpdateInpHeadlossFormula( ...
                    tempInpPath, ...
                    app.HeadlossDropDown.Value);

                % 2. Load the updated INP file in EPANET
                [d, NP, L, InitialD] = initializeNetwork(tempInpPath);

                % 3. Units come from the network that is actually loaded
                Units = detectNetworkUnits(d);
                Units.DiameterFileUnit = app.DUnitDropDown.Value;

                % 4. Load diameter/cost data, converted to the network unit
                [Din, Cost, D] = loadOptimizationData( ...
                    app.DFileStr, app.CostFileStr, ...
                    app.DUnitDropDown.Value, Units.DiameterUnit);

                validateOptimizationData(D, Cost);

                NodeTypes = d.getNodeType();
                JunctionIndices = find(strcmpi(NodeTypes, 'JUNCTION'));

                fixedPipes = validateFixedPipes( ...
                    app.FixedPipesEditField.Value, NP);

                variablePipes = setdiff(1:NP, fixedPipes);

                validateNetworkConsistency( ...
                    NP, L, InitialD, Din, D, Cost, ...
                    fixedPipes, variablePipes);

                Problem = buildOptimizationProblem( ...
                    Din, Cost, D, NP, L, InitialD, ...
                    fixedPipes, variablePipes, ...
                    app.PminEditField.Value, ...
                    app.VmaxEditField.Value, ...
                    JunctionIndices, Units);

                Config = buildAlgorithmConfig( ...
                    app.NSEditField.Value, ...
                    app.MaxGenEditField.Value);

            catch ME

                cleanupEpanetObject(d);
                cleanupTempInpFiles(tempInpPath);

                rethrow(ME);

            end

        end

        % --- Experiment-level results (statistics, charts, run table) ---
        function UpdateExperimentSummary(app, ExperimentResult, BestAlgorithm, BestRunIndex)

            app.UITableStats.Data = ...
                createExperimentSummaryTable(ExperimentResult);

            RunsTable = createRunsTable( ...
                ExperimentResult, BestAlgorithm, BestRunIndex);

            app.UITableRuns.Data = RunsTable;

            % Highlight the run that is displayed in the other tabs.
            removeStyle(app.UITableRuns);
            BestRows = find(strcmp(RunsTable.Best, 'Best'));

            if ~isempty(BestRows)
                addStyle(app.UITableRuns, ...
                    uistyle('FontWeight', 'bold', ...
                    'BackgroundColor', [0.85 0.95 0.85]), ...
                    'row', BestRows);
            end

            app.PlotConvergenceSummary(ExperimentResult);
            app.PlotScoreDistribution(ExperimentResult);

            app.TabGroup.SelectedTab = app.SummaryTab;

        end

        % --- Mean convergence with min-max band for each algorithm ---
        function PlotConvergenceSummary(app, ExperimentResult)

            ax = app.ConvAxes;
            cla(ax, 'reset');
            hold(ax, 'on');

            Colors.GA = [0.85 0.32 0.10];
            Colors.PSO = [0.00 0.45 0.74];

            Algorithms = ExperimentResult.Configuration.Algorithms;

            Handles = gobjects(0);
            Labels = {};

            for a = 1:numel(Algorithms)

                Name = Algorithms{a};
                C = ExperimentResult.Results.(Name).ConvergenceData;

                if isempty(C.Generation)
                    continue;
                end

                x = C.Generation(:);
                Color = Colors.(Name);

                fill(ax, [x; flipud(x)], ...
                    [C.Min(:); flipud(C.Max(:))], Color, ...
                    'FaceAlpha', 0.15, 'EdgeColor', 'none', ...
                    'HandleVisibility', 'off');

                h = plot(ax, x, C.Mean(:), ...
                    'LineWidth', 2, 'Color', Color);

                Handles(end + 1) = h; %#ok<AGROW>
                Labels{end + 1} = sprintf( ...
                    '%s (mean, %d runs)', Name, C.NumRuns(1)); %#ok<AGROW>

            end

            hold(ax, 'off');

            if ~isempty(Handles)
                legend(ax, Handles, Labels, 'Location', 'northeast');
            end

            title(ax, 'Convergence: mean and min-max band');
            xlabel(ax, 'Generation / Iteration');
            ylabel(ax, 'Best Cost');
            grid(ax, 'on');

        end

        % --- Box plot of final costs (feasible successful runs) ---
        function PlotScoreDistribution(app, ExperimentResult)

            ax = app.BoxAxes;
            cla(ax, 'reset');

            Algorithms = ExperimentResult.Configuration.Algorithms;

            Values = zeros(0, 1);
            Groups = strings(0, 1);

            for a = 1:numel(Algorithms)

                Name = Algorithms{a};
                Runs = ExperimentResult.Results.(Name).Runs;

                Ok = strcmp({Runs.Status}, 'Success') & ...
                    logical([Runs.Feasible]) & ...
                    isfinite([Runs.Score]);

                s = [Runs(Ok).Score]';

                Values = [Values; s]; %#ok<AGROW>
                Groups = [Groups; repmat(string(Name), numel(s), 1)]; %#ok<AGROW>

            end

            if isempty(Values)
                text(ax, 0.5, 0.5, 'No feasible runs to display', ...
                    'HorizontalAlignment', 'center');
                title(ax, 'Final cost distribution');
                return;
            end

            boxchart(ax, categorical(Groups, string(Algorithms)), Values);

            title(ax, 'Final cost distribution (feasible runs)');
            ylabel(ax, 'Cost');
            grid(ax, 'on');

        end

        % --- Convergence curve of the selected best run ---
        function PlotBestRunConvergence(app, BestAlgorithm, BestRunIndex, BestRun)

            if strcmp(BestAlgorithm, 'GA')
                LineColor = [0.85 0.32 0.1];
                xlabel(app.UIAxes, 'Generation');
            else
                LineColor = [0.0 0.45 0.74];
                xlabel(app.UIAxes, 'Iteration');
            end

            plot(app.UIAxes, 1:numel(BestRun.Conv), BestRun.Conv, ...
                'LineWidth', 2, 'Color', LineColor);

            if strcmp(BestAlgorithm, 'GA')
                xlabel(app.UIAxes, 'Generation');
            else
                xlabel(app.UIAxes, 'Iteration');
            end

            ylabel(app.UIAxes, 'Best Cost');

            title(app.UIAxes, sprintf( ...
                'Best %s Run %d Convergence', ...
                BestAlgorithm, BestRunIndex));

            grid(app.UIAxes, 'on');

        end

        % --- Best-design hydraulic results ---
        function Converged = UpdateGUIResults(app, d, Score, Position, Problem, Feasible)
            app.BestCost = Score;
            app.OptimalDiameters = Position';

            [app.NodePressures, app.PipeVelocities, Converged] = ...
                calculateHydraulicResults(d, app.OptimalDiameters, Problem.NP);

            % Best Design tab
            app.ResultUnits = Problem.Units;

            app.UITablePipes.Data = createPipeResultsTable( ...
                Problem.NP, ...
                app.OptimalDiameters, ...
                app.PipeVelocities, ...
                Problem.Units);

            if Feasible
                app.CostSummaryLabel.Text = ...
                    sprintf('Best cost: %.2f\nFeasible design', app.BestCost);
                app.CostSummaryLabel.FontColor = [0.1 0.5 0.1];
            else
                app.CostSummaryLabel.Text = ...
                    sprintf('Best cost: %.2f\nInfeasible design', app.BestCost);
                app.CostSummaryLabel.FontColor = [0.75 0.1 0.1];
            end

            % Hydraulic Results tab
            app.UITableNodes.Data = createNodeResultsTable( ...
                app.NodePressures, ...
                Problem.Pmin, ...
                Problem.Units);
            U = Problem.Units;

            app.NodeStatusLabel.Text = sprintf( ...
                'Min P: %.2f %s | Max V: %.2f %s', ...
                min(app.NodePressures), U.PressureUnit, ...
                max(app.PipeVelocities), U.VelocityUnit);

            numNodes = numel(app.NodePressures);

            bar(app.PressureAxes, 1:numNodes, app.NodePressures, 0.6, 'FaceColor', [0 0.45 0.74]);
            yline(app.PressureAxes, Problem.Pmin, '--r', ...
                sprintf('Pmin (%.1f %s)', Problem.Pmin, U.PressureUnit), 'LineWidth', 1.5);
            ylabel(app.PressureAxes, sprintf('Pressure (%s)', U.PressureUnit));
            grid(app.PressureAxes, 'on');

            bar(app.VelocityAxes, 1:Problem.NP, app.PipeVelocities, 0.6, 'FaceColor', [0.47 0.67 0.19]);
            yline(app.VelocityAxes, Problem.Vmax, '--r', ...
                sprintf('Vmax (%.1f %s)', Problem.Vmax, U.VelocityUnit), 'LineWidth', 1.5);
            ylabel(app.VelocityAxes, sprintf('Velocity (%s)', U.VelocityUnit));
            grid(app.VelocityAxes, 'on');
        end

        % --- Default experiment settings (used until the user applies others) ---
        function Settings = DefaultExperimentSettings(~)

            Defaults = buildAlgorithmConfig(100, 500);

            Settings.NumberOfRuns = 10;
            Settings.ExperimentSeed = 1;
            Settings.Algorithms = { ...
                'Genetic Algorithm (GA)', 'Particle Swarm (PSO)'};
            Settings.CacheMode = 'PerRun';
            Settings.GA = Defaults.GA;
            Settings.PSO = Defaults.PSO;
            Settings.Parallel = Defaults.Parallel;

        end

        % --- One-line description of the applied experiment settings ---
        function RefreshExperimentSettingsLabel(app)

            S = app.ExperimentSettings;

            Short = {};

            if any(strcmp(S.Algorithms, 'Genetic Algorithm (GA)'))
                Short{end + 1} = 'GA';
            end

            if any(strcmp(S.Algorithms, 'Particle Swarm (PSO)'))
                Short{end + 1} = 'PSO';
            end

            if S.Parallel.Enabled
                ParallelText = sprintf('on (%d workers)', ...
                    S.Parallel.NumWorkers);
            else
                ParallelText = 'off';
            end

            app.ExperimentSummaryLabel.Text = sprintf( ...
                '%s | %d runs each | seed %d | cache: %s | parallel: %s', ...
                strjoin(Short, ' + '), S.NumberOfRuns, ...
                S.ExperimentSeed, S.CacheMode, ParallelText);

        end

        % --- Experiment Settings Window ---
        function OpenExperimentSettings(app)

            Settings = app.ExperimentSettings;

            app.ExperimentSettingsFigure = uifigure( ...
                'Name', 'Experiment Settings', ...
                'Position', [200 100 500 570], ...
                'WindowStyle', 'modal');

            f = app.ExperimentSettingsFigure;

            uilabel(f, ...
                'Text', 'Experiment Configuration', ...
                'Position', [20 530 450 25], ...
                'FontSize', 16, ...
                'FontWeight', 'bold');

            % Algorithm selection
            app.GASelectCheckBox = uicheckbox(f, ...
                'Text', 'Genetic Algorithm (GA)', ...
                'Position', [25 490 200 22], ...
                'Value', any(strcmp(Settings.Algorithms, ...
                    'Genetic Algorithm (GA)')));

            app.PSOSelectCheckBox = uicheckbox(f, ...
                'Text', 'Particle Swarm (PSO)', ...
                'Position', [250 490 200 22], ...
                'Value', any(strcmp(Settings.Algorithms, ...
                    'Particle Swarm (PSO)')));

            uilabel(f, 'Text', 'Runs per algorithm:', ...
                'Position', [25 450 150 22]);

            app.NumberOfRunsEditField = uieditfield(f, 'numeric', ...
                'Position', [190 450 100 22], ...
                'Limits', [1 Inf], ...
                'RoundFractionalValues', 'on', ...
                'Value', Settings.NumberOfRuns);

            uilabel(f, 'Text', 'Experiment seed:', ...
                'Position', [25 415 150 22]);

            app.ExperimentSeedEditField = uieditfield(f, 'numeric', ...
                'Position', [190 415 100 22], ...
                'Limits', [0 double(intmax('uint32'))], ...
                'RoundFractionalValues', 'on', ...
                'Value', Settings.ExperimentSeed);

            uilabel(f, 'Text', 'Cache mode:', ...
                'Position', [25 380 150 22]);

            app.CacheModeDropDown = uidropdown(f, ...
                'Position', [190 380 200 22], ...
                'Items', {'PerRun', 'SharedExperiment'}, ...
                'Value', Settings.CacheMode);

            % GA parameters
            uilabel(f, 'Text', 'GA Parameters', ...
                'Position', [25 340 200 22], ...
                'FontWeight', 'bold');

            uilabel(f, 'Text', 'Crossover probability (Pc):', ...
                'Position', [25 310 170 22]);

            app.GAPcEditField = uieditfield(f, 'numeric', ...
                'Position', [210 310 100 22], ...
                'Limits', [0 1], ...
                'Value', Settings.GA.Pc);

            uilabel(f, 'Text', 'Mutation probability (Pm):', ...
                'Position', [25 280 170 22]);

            app.GAPmEditField = uieditfield(f, 'numeric', ...
                'Position', [210 280 100 22], ...
                'Limits', [0 1], ...
                'Value', Settings.GA.Pm);

            % PSO parameters
            uilabel(f, 'Text', 'PSO Parameters', ...
                'Position', [25 240 200 22], ...
                'FontWeight', 'bold');

            uilabel(f, 'Text', 'Inertia weight (w):', ...
                'Position', [25 210 170 22]);

            app.PSOwEditField = uieditfield(f, 'numeric', ...
                'Position', [210 210 100 22], ...
                'Limits', [0 Inf], ...
                'Value', Settings.PSO.w);

            uilabel(f, 'Text', 'Cognitive coefficient (c1):', ...
                'Position', [25 180 170 22]);

            app.PSOc1EditField = uieditfield(f, 'numeric', ...
                'Position', [210 180 100 22], ...
                'Limits', [0 Inf], ...
                'Value', Settings.PSO.c1);

            uilabel(f, 'Text', 'Social coefficient (c2):', ...
                'Position', [25 150 170 22]);

            app.PSOc2EditField = uieditfield(f, 'numeric', ...
                'Position', [210 150 100 22], ...
                'Limits', [0 Inf], ...
                'Value', Settings.PSO.c2);

            % Parallel settings
            app.ParallelCheckBox = uicheckbox(f, ...
                'Text', 'Enable parallel hydraulic evaluation', ...
                'Position', [25 110 300 22], ...
                'Value', Settings.Parallel.Enabled);

            uilabel(f, 'Text', 'Number of workers:', ...
                'Position', [25 80 170 22]);

            app.NumWorkersEditField = uieditfield(f, 'numeric', ...
                'Position', [210 80 100 22], ...
                'Limits', [1 Inf], ...
                'RoundFractionalValues', 'on', ...
                'Value', Settings.Parallel.NumWorkers);

            % Apply / Cancel
            uibutton(f, 'push', ...
                'Text', 'Apply', ...
                'Position', [250 20 100 32], ...
                'ButtonPushedFcn', ...
                @(btn, e) ApplyExperimentSettings(app));

            uibutton(f, 'push', ...
                'Text', 'Cancel', ...
                'Position', [365 20 100 32], ...
                'ButtonPushedFcn', ...
                @(btn, e) delete(f));

            % Dynamic enablement
            app.GASelectCheckBox.ValueChangedFcn = ...
                @(src, e) UpdateExperimentSettingsEnablement(app);

            app.PSOSelectCheckBox.ValueChangedFcn = ...
                @(src, e) UpdateExperimentSettingsEnablement(app);

            app.ParallelCheckBox.ValueChangedFcn = ...
                @(src, e) UpdateExperimentSettingsEnablement(app);

            UpdateExperimentSettingsEnablement(app);

        end

        % --- Enable/Disable Advanced Settings ---
        function UpdateExperimentSettingsEnablement(app)

            gaEnabled = app.GASelectCheckBox.Value;
            psoEnabled = app.PSOSelectCheckBox.Value;
            parallelEnabled = app.ParallelCheckBox.Value;

            app.GAPcEditField.Enable = matlab.lang.OnOffSwitchState(gaEnabled);
            app.GAPmEditField.Enable = matlab.lang.OnOffSwitchState(gaEnabled);

            app.PSOwEditField.Enable = matlab.lang.OnOffSwitchState(psoEnabled);
            app.PSOc1EditField.Enable = matlab.lang.OnOffSwitchState(psoEnabled);
            app.PSOc2EditField.Enable = matlab.lang.OnOffSwitchState(psoEnabled);

            app.NumWorkersEditField.Enable = ...
                matlab.lang.OnOffSwitchState(parallelEnabled);

        end

        % --- Save Experiment Settings ---
        function ApplyExperimentSettings(app)

            if ~app.GASelectCheckBox.Value && ...
                    ~app.PSOSelectCheckBox.Value

                uialert(app.ExperimentSettingsFigure, ...
                    'Select at least one algorithm.', ...
                    'Invalid Experiment Settings');
                return;
            end

            Settings.NumberOfRuns = ...
                app.NumberOfRunsEditField.Value;

            Settings.ExperimentSeed = ...
                app.ExperimentSeedEditField.Value;

            Settings.Algorithms = {};

            if app.GASelectCheckBox.Value
                Settings.Algorithms{end + 1} = ...
                    'Genetic Algorithm (GA)';
            end

            if app.PSOSelectCheckBox.Value
                Settings.Algorithms{end + 1} = ...
                    'Particle Swarm (PSO)';
            end

            Settings.CacheMode = app.CacheModeDropDown.Value;

            Settings.GA.Pc = app.GAPcEditField.Value;
            Settings.GA.Pm = app.GAPmEditField.Value;

            Settings.PSO.w = app.PSOwEditField.Value;
            Settings.PSO.c1 = app.PSOc1EditField.Value;
            Settings.PSO.c2 = app.PSOc2EditField.Value;

            Settings.Parallel.Enabled = ...
                app.ParallelCheckBox.Value;

            Settings.Parallel.NumWorkers = ...
                app.NumWorkersEditField.Value;

            app.ExperimentSettings = Settings;
            app.RefreshExperimentSettingsLabel();

            delete(app.ExperimentSettingsFigure);

        end

        % --- Export Excel ---
        function ExportToExcel(app, ~)

            [file, path] = uiputfile( ...
                '*.xlsx', ...
                'Save Comprehensive Results as Excel');

            if ischar(file)

                fullFileName = fullfile(path, file);

                try
                    exportResultsToExcel( ...
                        app.UITablePipes.Data, ...
                        app.UITableNodes.Data, ...
                        fullFileName, ...
                        app.ExperimentResult, ...
                        app.UITableStats.Data, ...
                        app.UITableRuns.Data, ...
                        app.ResultUnits);

                    uialert( ...
                        app.UIFigure, ...
                        'Results exported successfully!', ...
                        'Export Success', 'Icon', 'success');

                catch ME
                    uialert(app.UIFigure, ME.message, 'Export Error');
                end

            end

        end

    end

    % Component Initialization
    methods (Access = private)
        function createComponents(app)

            app.UIFigure = uifigure( ...
                'Position', [80 60 1240 740], ...
                'Name', 'WDS Optimization Toolkit v1.7.0');

            MainGrid = uigridlayout(app.UIFigure, [1 2]);
            MainGrid.ColumnWidth = {350, '1x'};
            MainGrid.RowHeight = {'1x'};
            MainGrid.Padding = [8 8 8 8];
            MainGrid.ColumnSpacing = 8;

            %% ---------------- Left side ----------------

            app.LeftPanel = uipanel(MainGrid, ...
                'Title', 'Input Controls & Constraints', ...
                'FontWeight', 'bold');
            placeIn(app.LeftPanel, 1, 1);

            LeftGrid = uigridlayout(app.LeftPanel, [7 1]);
            LeftGrid.RowHeight = {195, 120, 120, 100, 44, 34, '1x'};
            LeftGrid.Padding = [6 6 6 6];
            LeftGrid.RowSpacing = 6;

            % 1. Input files
            FilesPanel = uipanel(LeftGrid, ...
                'Title', '1. Input Files', 'FontWeight', 'bold');
            placeIn(FilesPanel, 1, 1);

            g = uigridlayout(FilesPanel, [5 2]);
            g.ColumnWidth = {115, '1x'};
            g.RowHeight = {24, 24, 24, 24, 48};
            g.Padding = [8 6 8 6];
            g.RowSpacing = 6;

            app.INPButton = uibutton(g, 'push', 'Text', 'Load .INP File', ...
                'ButtonPushedFcn', @(btn, e) SelectINPFile(app, e));
            placeIn(app.INPButton, 1, 1);
            app.INPLabel = uilabel(g, 'Text', 'No file selected');
            placeIn(app.INPLabel, 1, 2);

            app.DButton = uibutton(g, 'push', 'Text', 'Load D.txt', ...
                'ButtonPushedFcn', @(btn, e) SelectDFile(app, e));
            placeIn(app.DButton, 2, 1);
            app.DLabel = uilabel(g, 'Text', 'No file selected');
            placeIn(app.DLabel, 2, 2);

            app.CostButton = uibutton(g, 'push', 'Text', 'Load Cost.txt', ...
                'ButtonPushedFcn', @(btn, e) SelectCostFile(app, e));
            placeIn(app.CostButton, 3, 1);
            app.CostLabel = uilabel(g, 'Text', 'No file selected');
            placeIn(app.CostLabel, 3, 2);

            DUnitLabel = uilabel(g, 'Text', 'D.txt unit:');
            placeIn(DUnitLabel, 4, 1);
            app.DUnitDropDown = uidropdown(g, ...
                'Items', {'in', 'mm'}, 'Value', 'in');
            placeIn(app.DUnitDropDown, 4, 2);

            app.NetworkUnitsLabel = uilabel(g, ...
                'Text', 'Network units: load an .INP file.', ...
                'WordWrap', 'on', ...
                'VerticalAlignment', 'top', ...
                'FontColor', [0.35 0.35 0.35]);
            placeIn(app.NetworkUnitsLabel, 5, [1 2]);

            % 2. Hydraulics & algorithm size
            HydPanel = uipanel(LeftGrid, ...
                'Title', '2. Hydraulics & Algorithm Size', ...
                'FontWeight', 'bold');
            placeIn(HydPanel, 2, 1);

            g = uigridlayout(HydPanel, [3 2]);
            g.ColumnWidth = {135, '1x'};
            g.RowHeight = {24, 24, 24};
            g.Padding = [8 6 8 6];
            g.RowSpacing = 6;

            app.HeadlossDropDownLabel = uilabel(g, 'Text', 'Headloss Formula:');
            placeIn(app.HeadlossDropDownLabel, 1, 1);
            app.HeadlossDropDown = uidropdown(g, 'Items', ...
                {'Hazen-Williams (HW)', 'Darcy-Weisbach (DW)', 'Manning (CM)'});
            placeIn(app.HeadlossDropDown, 1, 2);

            app.NSEditFieldLabel = uilabel(g, 'Text', 'Population / Swarm:');
            placeIn(app.NSEditFieldLabel, 2, 1);
            app.NSEditField = uieditfield(g, 'numeric', 'Value', 100, ...
                'Limits', [1 Inf], 'RoundFractionalValues', 'on');
            placeIn(app.NSEditField, 2, 2);

            app.MaxGenEditFieldLabel = uilabel(g, 'Text', 'Max Gen / Iter:');
            placeIn(app.MaxGenEditFieldLabel, 3, 1);
            app.MaxGenEditField = uieditfield(g, 'numeric', 'Value', 500, ...
                'Limits', [1 Inf], 'RoundFractionalValues', 'on');
            placeIn(app.MaxGenEditField, 3, 2);

            % 3. Constraints
            ConPanel = uipanel(LeftGrid, ...
                'Title', '3. Constraints', 'FontWeight', 'bold');
            placeIn(ConPanel, 3, 1);

            g = uigridlayout(ConPanel, [3 2]);
            g.ColumnWidth = {150, '1x'};
            g.RowHeight = {24, 24, 24};
            g.Padding = [8 6 8 6];
            g.RowSpacing = 6;

            app.PminEditFieldLabel = uilabel(g, 'Text', 'Min Pressure (m):');
            placeIn(app.PminEditFieldLabel, 1, 1);
            app.PminEditField = uieditfield(g, 'numeric', 'Value', 30.0);
            placeIn(app.PminEditField, 1, 2);

            app.VmaxEditFieldLabel = uilabel(g, 'Text', 'Max Velocity (m/s):');
            placeIn(app.VmaxEditFieldLabel, 2, 1);
            app.VmaxEditField = uieditfield(g, 'numeric', 'Value', 2.5);
            placeIn(app.VmaxEditField, 2, 2);

            app.FixedPipesLabel = uilabel(g, 'Text', 'Fixed Pipe IDs (e.g. 1, 3):');
            placeIn(app.FixedPipesLabel, 3, 1);
            app.FixedPipesEditField = uieditfield(g, 'text', 'Value', '');
            placeIn(app.FixedPipesEditField, 3, 2);

            % 4. Experiment
            ExpPanel = uipanel(LeftGrid, ...
                'Title', '4. Experiment', 'FontWeight', 'bold');
            placeIn(ExpPanel, 4, 1);

            g = uigridlayout(ExpPanel, [2 1]);
            g.RowHeight = {28, '1x'};
            g.Padding = [8 6 8 6];
            g.RowSpacing = 4;

            app.ExperimentSettingsButton = uibutton(g, 'push', ...
                'Text', 'Experiment Settings...', ...
                'ButtonPushedFcn', @(btn, e) OpenExperimentSettings(app));
            placeIn(app.ExperimentSettingsButton, 1, 1);

            app.ExperimentSummaryLabel = uilabel(g, ...
                'Text', '', ...
                'WordWrap', 'on', ...
                'VerticalAlignment', 'top', ...
                'FontColor', [0.35 0.35 0.35]);
            placeIn(app.ExperimentSummaryLabel, 2, 1);

            % Run / Export / Status
            app.RunButton = uibutton(LeftGrid, 'push', ...
                'Text', 'Run Experiment', ...
                'BackgroundColor', [0.1 0.6 0.2], ...
                'FontColor', 'w', ...
                'FontSize', 13, ...
                'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, e) RunOptimization(app, e));
            placeIn(app.RunButton, 5, 1);

            app.ExportButton = uibutton(LeftGrid, 'push', ...
                'Text', 'Export Excel (Multi-Sheet)', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(btn, e) ExportToExcel(app, e));
            placeIn(app.ExportButton, 6, 1);

            app.StatusLabel = uilabel(LeftGrid, ...
                'Text', 'Status: Ready', ...
                'FontWeight', 'bold', ...
                'WordWrap', 'on', ...
                'VerticalAlignment', 'top');
            placeIn(app.StatusLabel, 7, 1);

            %% ---------------- Right side (tabs) ----------------

            app.TabGroup = uitabgroup(MainGrid);
            placeIn(app.TabGroup, 1, 2);

            app.SummaryTab = uitab(app.TabGroup, 'Title', 'Experiment Summary');
            app.CostTab = uitab(app.TabGroup, 'Title', 'Best Design');
            app.HydraulicsTab = uitab(app.TabGroup, 'Title', 'Hydraulic Results');
            app.RunsTab = uitab(app.TabGroup, 'Title', 'All Runs');

            % Tab: Experiment Summary
            g = uigridlayout(app.SummaryTab, [2 2]);
            g.RowHeight = {150, '1x'};
            g.ColumnWidth = {'3x', '2x'};
            g.Padding = [8 8 8 8];

            app.UITableStats = uitable(g, 'RowName', {});
            placeIn(app.UITableStats, 1, [1 2]);

            app.ConvAxes = uiaxes(g);
            placeIn(app.ConvAxes, 2, 1);
            title(app.ConvAxes, 'Convergence: mean and min-max band');
            xlabel(app.ConvAxes, 'Generation / Iteration');
            ylabel(app.ConvAxes, 'Best Cost');

            app.BoxAxes = uiaxes(g);
            placeIn(app.BoxAxes, 2, 2);
            title(app.BoxAxes, 'Final cost distribution (feasible runs)');

            % Tab: Best Design
            g = uigridlayout(app.CostTab, [2 2]);
            g.RowHeight = {'1x', 230};
            g.ColumnWidth = {'2x', '1x'};
            g.Padding = [8 8 8 8];

            app.UIAxes = uiaxes(g);
            placeIn(app.UIAxes, 1, [1 2]);
            title(app.UIAxes, 'Best Run Convergence');

            app.UITablePipes = uitable(g, 'RowName', {});
            placeIn(app.UITablePipes, 2, 1);

            app.CostSummaryLabel = uilabel(g, ...
                'Text', 'Best cost: -', ...
                'FontSize', 14, ...
                'FontWeight', 'bold', ...
                'WordWrap', 'on');
            placeIn(app.CostSummaryLabel, 2, 2);

            % Tab: Hydraulic Results
            g = uigridlayout(app.HydraulicsTab, [3 2]);
            g.RowHeight = {'1x', '1x', 28};
            g.ColumnWidth = {'2x', '1x'};
            g.Padding = [8 8 8 8];

            app.PressureAxes = uiaxes(g);
            placeIn(app.PressureAxes, 1, 1);
            title(app.PressureAxes, 'Node Pressures');
            xlabel(app.PressureAxes, 'Node');
            ylabel(app.PressureAxes, 'Pressure');

            app.VelocityAxes = uiaxes(g);
            placeIn(app.VelocityAxes, 2, 1);
            title(app.VelocityAxes, 'Pipe Velocities');
            xlabel(app.VelocityAxes, 'Pipe');
            ylabel(app.VelocityAxes, 'Velocity');

            app.UITableNodes = uitable(g, 'RowName', {});
            placeIn(app.UITableNodes, [1 2], 2);

            app.NodeStatusLabel = uilabel(g, ...
                'Text', 'Min P: - | Max V: -', ...
                'FontWeight', 'bold');
            placeIn(app.NodeStatusLabel, 3, [1 2]);

            % Tab: All Runs
            g = uigridlayout(app.RunsTab, [1 1]);
            g.Padding = [8 8 8 8];

            app.UITableRuns = uitable(g, ...
                'RowName', {}, 'ColumnSortable', true);
            placeIn(app.UITableRuns, 1, 1);

        end
    end

    methods (Access = public)
        function app = WDS_Optimizer_App
            createComponents(app);

            % Sensible defaults so the experiment can be run immediately.
            app.ExperimentSettings = app.DefaultExperimentSettings();
            app.RefreshExperimentSettingsLabel();

            if nargout == 0
                clear app
            end
        end
    end
end

% Place a component in a uigridlayout cell (row/column can be ranges).
function placeIn(component, row, column)
    component.Layout.Row = row;
    component.Layout.Column = column;
end
