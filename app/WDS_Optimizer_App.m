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

        % Live Monitor window
        LiveMonitorFigure        matlab.ui.Figure
        LiveRunAxes              matlab.ui.control.UIAxes
        LiveMonitorStatusLabel   matlab.ui.control.Label
        LiveConvergenceLine      matlab.graphics.chart.primitive.Line

        % Internal data storage
        InpFileStr
        DFileStr
        CostFileStr
        OptimalDiameters
        BestCost
        NodePressures
        PipeVelocities
        ExperimentResult
        CancelRequested logical = false
        ExperimentRunning = false

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

        % Persistence (Experiment Save/Load)
        LastProblem         struct = struct()
        LastConfig          struct = struct()
        LastBestAlgorithm   char = ''
        LastBestRunIndex    double = 0
        HydraulicsConverged logical = false
        LastExperimentSaved logical = true
        SaveButton          matlab.ui.control.Button
        LoadButton          matlab.ui.control.Button

        % Comparison
        ComparisonFigure    matlab.ui.Figure
        CompareButton       matlab.ui.control.Button
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

            app.CancelRequested = false;
            app.ExperimentRunning = true;

            % Warn about unsaved previous experiment
            if ~app.LastExperimentSaved && ~isempty(app.ExperimentResult)
                choice = uiconfirm(app.UIFigure, ...
                    ['The current experiment has not been saved. ' ...
                    'Starting a new run will discard it. Continue?'], ...
                    'Unsaved Experiment', ...
                    'Options', {'Continue', 'Cancel'}, ...
                    'DefaultOption', 2, 'CancelOption', 2);
                if strcmp(choice, 'Cancel')
                    app.ExperimentRunning = false;   % ← اضافه شود
                    return;
                end
            end

            app.StatusLabel.Text = 'Status: Running Experiment...';   % ← منتقل شد

            app.RunButton.Text = 'Cancel Experiment';
            app.RunButton.BackgroundColor = [0.85 0.15 0.15];
            app.RunButton.FontColor = 'w';
            app.RunButton.Enable = 'on';
            app.ExportButton.Enable = 'off';
            app.SaveButton.Enable = 'off';
            app.LoadButton.Enable = 'off';       % ← اضافه شود
            app.CompareButton.Enable = 'off';    % ← اضافه شود

            app.CreateLiveMonitorWindow();
            drawnow;

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

                %% Live Monitor callback

                app.UpdateLiveMonitorStatus( ...
                    'Preparing optimization problem...');

                ExperimentOptions.ProgressCallback = ...
                    @(ProgressInfo) app.UpdateLiveMonitor(ProgressInfo);

                ExperimentOptions.CancelCallback = ...
                    @() app.CancelRequested;

                drawnow;

                %% 3. Initialize parallel hydraulic infrastructure

                if Config.Parallel.Enabled

                    app.UpdateLiveMonitorStatus( ...
                        'Starting parallel workers...');

                    initializeParallelHydraulics( ...
                        tempInpPath, ...
                        Config.Parallel.NumWorkers);

                    parallelInitialized = true;
                end

                %% 4. Run the experiment

                app.UpdateLiveMonitorStatus(sprintf( ...
                    'Running %s: %d run(s) per algorithm...', ...
                    strjoin(ExperimentAlgorithms, ' + '), ...
                    ExperimentOptions.NumberOfRuns));

                ExpResult = runExperiment( ...
                    d, Problem, Config, ExperimentOptions);

                app.UpdateLiveMonitorStatus('Collecting results...');

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

                    if app.CancelRequested

                        error( ...
                            'WDSOptimizer:ExperimentCancelled', ...
                            'Experiment cancelled by user.');

                    else

                        error( ...
                            'WDSOptimizer:NoSuccessfulRuns', ...
                            ['No successful experiment runs are available. ' ...
                            'Check the reported run errors and try again.']);

                    end

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

                Hydraulics = app.ComputeHydraulicResults(d, BestRun.Position, Problem);
                app.DisplayResults(BestRun.Score, BestRun.Position, Problem, ...
                    Hydraulics, BestRun.Feasible);

                Converged = Hydraulics.Converged;

                if app.CancelRequested
                    app.StatusLabel.Text = ...
                        'Status: Experiment cancelled. Successful results preserved.';
                end

                cleanupEpanetObject(d);
                d = [];

                cleanupTempInpFiles(tempInpPath);

                %% 10. Report experiment and hydraulic status

                TotalRuns = 0;
                SuccessfulRuns = 0;
                FailedRuns = 0;
                CancelledRuns = 0;
                NotStartedRuns = 0;

                for a = 1:numel(ExperimentAlgorithms)

                    Algorithm = ExperimentAlgorithms{a};

                    Runs = ExpResult.Results.(Algorithm).Runs;

                    TotalRuns = TotalRuns + numel(Runs);

                    SuccessfulRuns = SuccessfulRuns + ...
                        sum(strcmp({Runs.Status}, 'Success'));

                    FailedRuns = FailedRuns + ...
                        sum(strcmp({Runs.Status}, 'Failed'));

                    CancelledRuns = CancelledRuns + ...
                        sum(strcmp({Runs.Status}, 'Cancelled'));

                    NotStartedRuns = NotStartedRuns + ...
                        sum(strcmp({Runs.Status}, 'NotStarted'));

                end

                if app.CancelRequested

                    app.StatusLabel.Text = sprintf( ...
                        ['Experiment cancelled: %d/%d succeeded, ' ...
                         '%d cancelled, %d failed, %d not started.'], ...
                        SuccessfulRuns, TotalRuns, ...
                        CancelledRuns, FailedRuns, NotStartedRuns);

                elseif SuccessfulRuns == TotalRuns

                    app.StatusLabel.Text = sprintf( ...
                        'Experiment completed: %d/%d runs succeeded.', ...
                        SuccessfulRuns, TotalRuns);

                else

                    app.StatusLabel.Text = sprintf( ...
                        ['Experiment finished: %d/%d succeeded, ' ...
                         '%d failed, %d cancelled, %d not started.'], ...
                        SuccessfulRuns, TotalRuns, ...
                        FailedRuns, CancelledRuns, NotStartedRuns);

                end

                if ~isempty(app.LiveMonitorFigure) && ...
                        isvalid(app.LiveMonitorFigure)
                    close(app.LiveMonitorFigure);
                end

                if ~Converged && ~app.CancelRequested

                    uialert( ...
                        app.UIFigure, ...
                        ['The hydraulic solution for the selected design ', ...
                        'did not converge. Displayed pressures and ', ...
                        'velocities may not be reliable.'], ...
                        'Hydraulic Warning', ...
                        'Icon', 'warning');

                end

                app.ExportButton.Enable = 'on';

                app.LastProblem         = Problem;
                app.LastConfig          = Config;
                app.LastBestAlgorithm   = BestAlgorithm;
                app.LastBestRunIndex    = BestRunIndex;
                app.HydraulicsConverged = Converged;
                app.LastExperimentSaved = false;
                app.SaveButton.Enable   = 'on';

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

                if ~isempty(app.LiveMonitorFigure) && ...
                        isvalid(app.LiveMonitorFigure)
                    close(app.LiveMonitorFigure);
                end

                if strcmp(ME.identifier, ...
                        'WDSOptimizer:ExperimentCancelled')

                    app.StatusLabel.Text = ...
                        'Status: Experiment Cancelled.';

                else

                    app.StatusLabel.Text = 'Status: Experiment Error!';

                    uialert( ...
                        app.UIFigure, ...
                        ME.message, ...
                        'Experiment Execution Error');

                end

            end

            app.ExperimentRunning = false;
            app.LoadButton.Enable = 'on';
            app.CompareButton.Enable = 'on';     % ← اضافه شود
            app.CancelRequested = false;

            app.RunButton.Text = 'Run Experiment';
            app.RunButton.BackgroundColor = [0.1 0.6 0.2];
            app.RunButton.FontColor = 'w';
            app.RunButton.Enable = 'on';

        end

        function OnRunButtonPressed(app)

            if app.ExperimentRunning
                app.CancelRequested = true;
                app.RunButton.Enable = 'off';
                app.StatusLabel.Text = 'Status: Cancellation requested...';
                drawnow;
            else
                app.RunOptimization([]);
            end

        end

        % --- Create the Live Monitor window ---
        function CreateLiveMonitorWindow(app)

            if ~isempty(app.LiveMonitorFigure) && ...
                    isvalid(app.LiveMonitorFigure)
                close(app.LiveMonitorFigure);
            end

            app.LiveMonitorFigure = uifigure( ...
                'Name', 'WDS Optimizer - Live Monitor', ...
                'Position', [250 150 850 520], ...
                'CloseRequestFcn', ...
                @(src, evt) app.OnLiveMonitorCloseRequest());

            g = uigridlayout(app.LiveMonitorFigure, [2 1]);
            g.RowHeight = {45, '1x'};
            g.Padding = [10 10 10 10];
            g.RowSpacing = 8;

            app.LiveMonitorStatusLabel = uilabel(g, ...
                'Text', 'Preparing experiment...', ...
                'FontWeight', 'bold', ...
                'WordWrap', 'on');
            app.LiveMonitorStatusLabel.Layout.Row = 1;
            app.LiveMonitorStatusLabel.Layout.Column = 1;

            app.LiveRunAxes = uiaxes(g);
            app.LiveRunAxes.Layout.Row = 2;
            app.LiveRunAxes.Layout.Column = 1;

            title(app.LiveRunAxes, 'Current Run Convergence');
            xlabel(app.LiveRunAxes, 'Generation / Iteration');
            ylabel(app.LiveRunAxes, 'Best Cost');
            grid(app.LiveRunAxes, 'on');

            cla(app.LiveRunAxes, 'reset');
            app.LiveConvergenceLine = plot( ...
                app.LiveRunAxes, nan, nan, 'LineWidth', 2);

            title(app.LiveRunAxes, 'Current Run Convergence');
            xlabel(app.LiveRunAxes, 'Generation / Iteration');
            ylabel(app.LiveRunAxes, 'Best Cost');
            grid(app.LiveRunAxes, 'on');

            drawnow;
        end

        % --- Handle Live Monitor window closure ---
        function OnLiveMonitorCloseRequest(app)

            if ~isempty(app.LiveMonitorFigure) && ...
                    isvalid(app.LiveMonitorFigure)
                delete(app.LiveMonitorFigure);
            end

        end

        % --- Safely update Live Monitor status ---
        function UpdateLiveMonitorStatus(app, StatusText)

            if isempty(app.LiveMonitorFigure) || ...
                    ~isvalid(app.LiveMonitorFigure) || ...
                    isempty(app.LiveMonitorStatusLabel) || ...
                    ~isvalid(app.LiveMonitorStatusLabel)
                return;
            end

            app.LiveMonitorStatusLabel.Text = StatusText;

            drawnow limitrate;
        end

        % --- Receive live progress reports ---
        function UpdateLiveMonitor(app, ProgressInfo)

            if isempty(app.LiveMonitorFigure) || ...
                    ~isvalid(app.LiveMonitorFigure) || ...
                    isempty(app.LiveMonitorStatusLabel) || ...
                    ~isvalid(app.LiveMonitorStatusLabel) || ...
                    isempty(app.LiveRunAxes) || ...
                    ~isvalid(app.LiveRunAxes) || ...
                    isempty(app.LiveConvergenceLine) || ...
                    ~isvalid(app.LiveConvergenceLine)
                return;
            end

            if ProgressInfo.Feasible
                FeasibilityText = 'Feasible';
            else
                FeasibilityText = 'Infeasible';
            end

            app.LiveMonitorStatusLabel.Text = sprintf( ...
                '%s | Generation %d/%d | Best cost: %.2f | %s', ...
                ProgressInfo.RunLabel, ...
                ProgressInfo.Generation, ...
                ProgressInfo.MaxGenerations, ...
                ProgressInfo.BestCost, ...
                FeasibilityText);

            app.LiveConvergenceLine.XData = 1:ProgressInfo.Generation;
            app.LiveConvergenceLine.YData = ProgressInfo.Convergence;

            if strcmp(ProgressInfo.Algorithm, 'GA')
                app.LiveConvergenceLine.Color = [1 0 0];  % Red
            elseif strcmp(ProgressInfo.Algorithm, 'PSO')
                app.LiveConvergenceLine.Color = [0 0 1];  % Blue
            end

            drawnow limitrate;

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

        % --- Hydraulic computation (no UI side effects) ---
        function Hydraulics = ComputeHydraulicResults(~, d, Position, Problem)

            [Hydraulics.NodePressures, Hydraulics.PipeVelocities, ...
                Hydraulics.Converged] = ...
                calculateHydraulicResults(d, Position(:), Problem.NP);
        end

        % --- UI display only (no d, no hydraulics computation) ---
        function DisplayResults(app, Score, Position, Problem, Hydraulics, Feasible)

            app.BestCost          = Score;
            app.OptimalDiameters  = Position(:)';
            app.NodePressures     = Hydraulics.NodePressures;
            app.PipeVelocities    = Hydraulics.PipeVelocities;

            % Best Design tab
            app.ResultUnits = Problem.Units;
            app.UITablePipes.Data = createPipeResultsTable( ...
                Problem.NP, app.OptimalDiameters, app.PipeVelocities, Problem.Units);

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
                app.NodePressures, Problem.Pmin, Problem.Units);
            U = Problem.Units;

            app.NodeStatusLabel.Text = sprintf( ...
                'Min P: %.2f %s | Max V: %.2f %s', ...
                min(app.NodePressures), U.PressureUnit, ...
                max(app.PipeVelocities), U.VelocityUnit);

            numNodes = numel(app.NodePressures);

            bar(app.PressureAxes, 1:numNodes, app.NodePressures, 0.6, ...
                'FaceColor', [0 0.45 0.74]);
            yline(app.PressureAxes, Problem.Pmin, '--r', ...
                sprintf('Pmin (%.1f %s)', Problem.Pmin, U.PressureUnit), ...
                'LineWidth', 1.5);
            ylabel(app.PressureAxes, sprintf('Pressure (%s)', U.PressureUnit));
            grid(app.PressureAxes, 'on');

            bar(app.VelocityAxes, 1:Problem.NP, app.PipeVelocities, 0.6, ...
                'FaceColor', [0.47 0.67 0.19]);
            yline(app.VelocityAxes, Problem.Vmax, '--r', ...
                sprintf('Vmax (%.1f %s)', Problem.Vmax, U.VelocityUnit), ...
                'LineWidth', 1.5);
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

        % --- Save current experiment to .wdsx ---
        function SaveExperiment(app)

            if isempty(app.ExperimentResult) || isempty(app.LastProblem) || ...
                    isempty(app.LastBestAlgorithm)

                uialert(app.UIFigure, ...
                    'There is no completed experiment to save.', ...
                    'Nothing to Save');
                return;
            end

            % Warn if settings differ from what was actually run
            C = app.ExperimentResult.Configuration;
            SettingsChanged = ...
                C.NS ~= app.NSEditField.Value || ...
                C.MaxGen ~= app.MaxGenEditField.Value || ...
                C.ExperimentSeed ~= app.ExperimentSettings.ExperimentSeed;

            if SettingsChanged
                choice = uiconfirm(app.UIFigure, ...
                    ['Settings have changed since the last run. ' ...
                    'The saved file will contain the current settings ' ...
                    'paired with the previous results. Save anyway?'], ...
                    'Settings Mismatch', ...
                    'Options', {'Save Anyway', 'Cancel'}, ...
                    'DefaultOption', 2, 'CancelOption', 2);

                if strcmp(choice, 'Cancel')
                    return;
                end
            end

            [file, path] = uiputfile('*.wdsx', 'Save Experiment', ...
                sprintf('WDS_Exp_%s.wdsx', ...
                    char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'))));

            if ~ischar(file)
                return;
            end

            fullPath = fullfile(path, file);

            try
                SavedExperiment = app.BuildExperimentSnapshot(); 
                save(fullPath, 'SavedExperiment', '-v7.3', '-mat');

                app.LastExperimentSaved = true;
                app.StatusLabel.Text = sprintf( ...
                    'Status: Experiment saved to %s.', file);

            catch ME
                uialert(app.UIFigure, ME.message, 'Save Error');
            end
        end

        % --- Load an experiment from .wdsx ---
        function LoadExperiment(app)

            if app.ExperimentRunning
                uialert(app.UIFigure, ...
                    'Cancel the running experiment first.', ...
                    'Cannot Load');
                return;
            end

            if ~app.LastExperimentSaved && ~isempty(app.ExperimentResult)
                choice = uiconfirm(app.UIFigure, ...
                    ['The current experiment has not been saved. ' ...
                    'Loading a new one will discard it. Continue?'], ...
                    'Unsaved Experiment', ...
                    'Options', {'Continue', 'Cancel'}, ...
                    'DefaultOption', 2, 'CancelOption', 2);

                if strcmp(choice, 'Cancel')
                    return;
                end
            end

            [file, path] = uigetfile('*.wdsx', 'Load Experiment');
            if ~ischar(file)
                return;
            end

            try
                S = load(fullfile(path, file), '-mat');
                if ~isfield(S, 'SavedExperiment')
                    error('WDS:InvalidFile', ...
                        'The selected file is not a WDS Optimizer experiment.');
                end
                Exp = S.SavedExperiment;

                validateSavedExperiment(Exp);
                app.ApplyLoadedExperiment(Exp, file);

            catch ME
                uialert(app.UIFigure, ME.message, 'Load Error');
            end
        end

        % --- Restore app state from a loaded experiment ---
        function ApplyLoadedExperiment(app, Exp, fileName)

            % 1. Restore input files to a fresh temp folder
            [inpPath, dPath, costPath] = restoreInputFiles(Exp.Environment);

            app.InpFileStr  = inpPath;
            app.DFileStr    = dPath;
            app.CostFileStr = costPath;

            app.INPLabel.Text  = sprintf('%s (loaded)', Exp.Environment.InpFileName);
            app.DLabel.Text    = sprintf('%s (loaded)', Exp.Environment.DFileName);
            app.CostLabel.Text = sprintf('%s (loaded)', Exp.Environment.CostFileName);

            % 2. Restore UI input fields from the saved experiment
            app.HeadlossDropDown.Value = Exp.Environment.Headloss;
            app.DUnitDropDown.Value    = Exp.Environment.DUnit;

            app.PminEditField.Value       = Exp.Problem.Pmin;
            app.VmaxEditField.Value       = Exp.Problem.Vmax;
            app.NSEditField.Value         = Exp.Config.NS;
            app.MaxGenEditField.Value     = Exp.Config.MaxGen;
            app.FixedPipesEditField.Value = formatPipeList(Exp.Problem.FixedPipes);

            app.ExperimentSettings = Exp.Settings;
            app.RefreshExperimentSettingsLabel();

            % 3. Restore units labels (from saved Problem)
            app.NetworkUnits = Exp.Problem.Units;
            app.ApplyUnitLabels();

            % 4. Restore internal state
            app.LastProblem         = Exp.Problem;
            app.LastConfig          = Exp.Config;
            app.LastBestAlgorithm   = Exp.Best.Algorithm;
            app.LastBestRunIndex    = Exp.Best.RunIndex;
            app.ExperimentResult    = Exp.ExperimentResult;
            app.HydraulicsConverged = Exp.Hydraulics.Converged;

            % 5. Repopulate UI without re-running anything
            app.UpdateExperimentSummary(Exp.ExperimentResult, ...
                Exp.Best.Algorithm, Exp.Best.RunIndex);

            BestRun = Exp.ExperimentResult.Results.( ...
                Exp.Best.Algorithm).Runs(Exp.Best.RunIndex);

            app.PlotBestRunConvergence(Exp.Best.Algorithm, ...
                Exp.Best.RunIndex, BestRun);

            app.DisplayResults(Exp.Best.Score, Exp.Best.Position, ...
                Exp.Problem, Exp.Hydraulics, Exp.Best.Feasible);

            % 6. Update state flags
            app.LastExperimentSaved = true;
            app.ExportButton.Enable = 'on';
            app.SaveButton.Enable   = 'on';
            app.StatusLabel.Text = sprintf( ...
                'Status: Loaded "%s" (saved %s).', fileName, ...
                char(Exp.Timestamp));
        end

        % --- Build a saveable snapshot of the current experiment state ---
        function Exp = BuildExperimentSnapshot(app)

            Exp = struct();
            Exp.FormatVersion = 1;
            Exp.AppVersion    = '1.7.0';
            Exp.Timestamp     = datetime('now');

            % ---- Environment ----
            inpContent  = readFileContent(app.InpFileStr);
            dContent    = readFileContent(app.DFileStr);
            costContent = readFileContent(app.CostFileStr);

            [~, inpBase,  inpExt]  = fileparts(app.InpFileStr);
            [~, dBase,    dExt]    = fileparts(app.DFileStr);
            [~, costBase, costExt] = fileparts(app.CostFileStr);

            Exp.Environment.InpFileName     = [inpBase  inpExt];
            Exp.Environment.InpFilePath     = app.InpFileStr;
            Exp.Environment.InpFileContent  = inpContent;
            Exp.Environment.InpFileHash     = computeStringHash(inpContent);

            Exp.Environment.DFileName       = [dBase dExt];
            Exp.Environment.DFilePath       = app.DFileStr;
            Exp.Environment.DFileContent    = dContent;
            Exp.Environment.DFileHash       = computeStringHash(dContent);

            Exp.Environment.CostFileName    = [costBase costExt];
            Exp.Environment.CostFilePath    = app.CostFileStr;
            Exp.Environment.CostFileContent = costContent;
            Exp.Environment.CostFileHash    = computeStringHash(costContent);

            Exp.Environment.DUnit    = app.DUnitDropDown.Value;
            Exp.Environment.Headloss = app.HeadlossDropDown.Value;

            % ---- Settings + Config ----
            Exp.Settings = app.ExperimentSettings;
            Exp.Config   = sanitizeConfigForSave(app.LastConfig);

            % ---- Problem ----
            Exp.Problem  = app.LastProblem;

            % ---- ExperimentResult ----
            Exp.ExperimentResult = app.ExperimentResult;

            % ---- Best ----
            BestRun = Exp.ExperimentResult.Results.(app.LastBestAlgorithm)...
                .Runs(app.LastBestRunIndex);

            Exp.Best.Algorithm = app.LastBestAlgorithm;
            Exp.Best.RunIndex  = app.LastBestRunIndex;
            Exp.Best.Score     = BestRun.Score;
            Exp.Best.Position  = BestRun.Position;
            Exp.Best.Feasible  = BestRun.Feasible;

            % ---- Hydraulics ----
            Exp.Hydraulics.NodePressures  = app.NodePressures;
            Exp.Hydraulics.PipeVelocities = app.PipeVelocities;
            Exp.Hydraulics.Converged      = app.HydraulicsConverged;
        end

        % --- Compare two saved experiments ---
        function CompareExperiments(app)

            [fileA, pathA] = uigetfile('*.wdsx', ...
                'Select Experiment A (.wdsx)');
            if ~ischar(fileA), return; end

            [fileB, pathB] = uigetfile('*.wdsx', ...
                'Select Experiment B (.wdsx)');
            if ~ischar(fileB), return; end

            try
                SA = load(fullfile(pathA, fileA), '-mat');
                if ~isfield(SA, 'SavedExperiment')
                    error('WDS:InvalidFile', ...
                        'Experiment A is not a WDS Optimizer file.');
                end
                ExpA = SA.SavedExperiment;
                validateSavedExperiment(ExpA);

                SB = load(fullfile(pathB, fileB), '-mat');
                if ~isfield(SB, 'SavedExperiment')
                    error('WDS:InvalidFile', ...
                        'Experiment B is not a WDS Optimizer file.');
                end
                ExpB = SB.SavedExperiment;
                validateSavedExperiment(ExpB);
            catch ME
                uialert(app.UIFigure, ME.message, 'Comparison Load Error');
                return;
            end

            if ~strcmp(ExpA.Environment.InpFileHash, ...
                    ExpB.Environment.InpFileHash)
                choice = uiconfirm(app.UIFigure, ...
                    ['The two experiments were run on different networks. ' ...
                     'Cost values are in different scales and are not ' ...
                     'directly comparable. Proceed anyway?'], ...
                    'Different Networks', ...
                    'Options', {'Proceed', 'Cancel'}, ...
                    'DefaultOption', 2, 'CancelOption', 2);
                if strcmp(choice, 'Cancel'), return; end
            end

            app.ShowComparisonWindow(ExpA, ExpB, fileA, fileB);
        end

        % --- Build and display the comparison window ---
        function ShowComparisonWindow(app, ExpA, ExpB, NameA, NameB)

            if ~isempty(app.ComparisonFigure) && ...
                    isvalid(app.ComparisonFigure)
                delete(app.ComparisonFigure);
            end

            app.ComparisonFigure = uifigure( ...
                'Name', sprintf('Comparison: %s vs %s', NameA, NameB), ...
                'Position', [120 60 1100 720]);

            f = app.ComparisonFigure;

            g = uigridlayout(f, [2 1]);
            g.RowHeight = {'1x', 44};
            g.Padding = [10 10 10 10];
            g.RowSpacing = 8;

            Tabs = uitabgroup(g);
            placeIn(Tabs, 1, 1);

            % ---- Summary tab ----
            gs = uigridlayout(uitab(Tabs, 'Title', 'Summary'), [2 1]);
            gs.RowHeight = {28, '1x'};
            gs.Padding = [8 8 8 8];
            gs.RowSpacing = 6;

            uilabel(gs, ...
                'Text', ['Delta = B - A  (positive means B is higher; ' ...
                         'for cost, lower is better)'], ...
                'FontAngle', 'italic', ...
                'FontColor', [0.4 0.4 0.4]);

            Tbl = uitable(gs, ...
                'ColumnName', ...
                    {'Metric', 'Experiment A', 'Experiment B', 'Delta (B - A)'}, ...
                'RowName', {}, ...
                'ColumnWidth', {230, 200, 200, 160});
            placeIn(Tbl, 2, 1);

            [Data, SectionRows] = ...
                buildComparisonSummaryData(ExpA, ExpB, NameA, NameB);
            Tbl.Data = Data;

            if any(SectionRows)
                addStyle(Tbl, ...
                    uistyle('FontWeight', 'bold', ...
                            'BackgroundColor', [0.92 0.92 0.92]), ...
                    'row', find(SectionRows));
            end

            % ---- Convergence tab ----
            ConvTab = uitab(Tabs, 'Title', 'Convergence');
            gc = uigridlayout(ConvTab, [1 1]);
            gc.Padding = [8 8 8 8];
            ComparisonConvAxes = uiaxes(gc);
            plotComparisonConvergence(ComparisonConvAxes, ExpA, ExpB, NameA, NameB);

            % ---- Distribution tab ----
            DistTab = uitab(Tabs, 'Title', 'Distribution');
            gd = uigridlayout(DistTab, [1 1]);
            gd.Padding = [8 8 8 8];
            DistAxes = uiaxes(gd);
            plotComparisonDistribution(DistAxes, ExpA, ExpB);

            % ---- Bottom button row ----
            BtnRow = uigridlayout(g, [1 3]);
            BtnRow.ColumnWidth = {'1x', 200, 100};
            BtnRow.Padding = [0 0 0 0];
            BtnRow.ColumnSpacing = 6;
            placeIn(BtnRow, 2, 1);

            uilabel(BtnRow, 'Text', '');  % spacer

            uibutton(BtnRow, 'push', ...
                'Text', 'Export Comparison...', ...
                'ButtonPushedFcn', ...
                    @(~, ~) app.ExportComparison(ExpA, ExpB, NameA, NameB));

            uibutton(BtnRow, 'push', ...
                'Text', 'Close', ...
                'ButtonPushedFcn', @(~, ~) delete(f));
        end

        % --- Export comparison workbook ---
        function ExportComparison(app, ExpA, ExpB, NameA, NameB)

            [file, path] = uiputfile( ...
                '*.xlsx', ...
                'Save Comparison as Excel', ...
                sprintf('WDS_Compare_%s.xlsx', ...
                    char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'))));

            if ~ischar(file), return; end

            try
                exportComparisonToExcel(ExpA, ExpB, NameA, NameB, ...
                    fullfile(path, file));
                uialert(app.UIFigure, ...
                    'Comparison exported successfully!', ...
                    'Export Success', 'Icon', 'success');
            catch ME
                uialert(app.UIFigure, ME.message, 'Export Error');
            end
        end

    end

    % Component Initialization
    methods (Access = private)
        function createComponents(app)

            app.UIFigure = uifigure( ...
                'Position', [80 20 1240 740], ...
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
            LeftGrid.RowHeight = {190, 115, 115, 120, 40, 34, '1x'};
            LeftGrid.Padding = [6 6 6 6];
            LeftGrid.RowSpacing = 5;

            % 1. Input files
            FilesPanel = uipanel(LeftGrid, ...
                'Title', '1. Input Files', 'FontWeight', 'bold');
            placeIn(FilesPanel, 1, 1);

            g = uigridlayout(FilesPanel, [5 2]);
            g.ColumnWidth = {100, '1x'};
            g.RowHeight = {22, 22, 22, 22, 40};
            g.Padding = [4 4 4 4];
            g.RowSpacing = 4;

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
            g.ColumnWidth = {110, '1x'};
            g.RowHeight = {22, 22, 22};
            g.Padding = [4 4 4 4];
            g.RowSpacing = 4;

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
            g.ColumnWidth = {120, '1x'};
            g.RowHeight = {22, 22, 22};
            g.Padding = [4 4 4 4];
            g.RowSpacing = 4;

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

            g = uigridlayout(ExpPanel, [3 1]);
            g.RowHeight = {24, 24, '1x'};
            g.Padding = [4 4 4 4];
            g.RowSpacing = 4;

            app.ExperimentSettingsButton = uibutton(g, 'push', ...
                'Text', 'Experiment Settings...', ...
                'ButtonPushedFcn', @(btn, e) OpenExperimentSettings(app));
            placeIn(app.ExperimentSettingsButton, 1, 1);

            app.SaveButton = uibutton(g, 'push', ...
                'Text', 'Save Experiment...', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(btn, e) SaveExperiment(app));
            placeIn(app.SaveButton, 2, 1);

            app.ExperimentSummaryLabel = uilabel(g, ...
                'Text', '', ...
                'WordWrap', 'on', ...
                'VerticalAlignment', 'top', ...
                'FontColor', [0.35 0.35 0.35]);
            placeIn(app.ExperimentSummaryLabel, 3, 1);

            % Run / Export / Status
            app.RunButton = uibutton(LeftGrid, 'push', ...
                'Text', 'Run Experiment', ...
                'BackgroundColor', [0.1 0.6 0.2], ...
                'FontColor', 'w', ...
                'FontSize', 13, ...
                'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(btn, e) app.OnRunButtonPressed());
            placeIn(app.RunButton, 5, 1);

             % ردیف ۶: Load، Compare و Export در یک ردیف
            BottomButtons = uigridlayout(LeftGrid, [1 3]);
            BottomButtons.ColumnWidth = {'1x', '1x', '1x'};
            BottomButtons.Padding = [0 0 0 0];
            BottomButtons.ColumnSpacing = 4;
            placeIn(BottomButtons, 6, 1);

            app.LoadButton = uibutton(BottomButtons, 'push', ...
                'Text', 'Load...', ...
                'Tooltip', 'Load a saved experiment (.wdsx)', ...
                'ButtonPushedFcn', @(btn, e) LoadExperiment(app));
            placeIn(app.LoadButton, 1, 1);

            app.CompareButton = uibutton(BottomButtons, 'push', ...
                'Text', 'Compare...', ...
                'Tooltip', 'Compare two saved experiments (.wdsx)', ...
                'ButtonPushedFcn', @(btn, e) CompareExperiments(app));
            placeIn(app.CompareButton, 1, 2);

            app.ExportButton = uibutton(BottomButtons, 'push', ...
                'Text', 'Export...', ...
                'Tooltip', 'Export results to multi-sheet Excel workbook', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', @(btn, e) ExportToExcel(app, e));
            placeIn(app.ExportButton, 1, 3);

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
