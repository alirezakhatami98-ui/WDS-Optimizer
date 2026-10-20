function ExperimentResult = runExperiment( ...
    d, Problem, Config, ExperimentOptions)
%RUNEXPERIMENT Execute reproducible optimization experiments.
%
% Required ExperimentOptions fields:
%   NumberOfRuns
%   Algorithms       - {'GA'}, {'PSO'}, or {'GA','PSO'}
%   ExperimentSeed
%   CacheMode        - 'PerRun' or 'SharedExperiment'
%
% The EPANET object, Problem, and base Config must already be prepared.
% Parallel hydraulic infrastructure, if enabled, must already be initialized.
%
% Each algorithm is executed sequentially. All selected algorithms use
% the same pre-generated run-seed set.

    %% Validate required inputs

    if nargin ~= 4
        error('runExperiment:InvalidInputCount', ...
            ['Expected d, Problem, Config, and ' ...
             'ExperimentOptions.']);
    end

    requiredFields = { ...
        'NumberOfRuns', ...
        'Algorithms', ...
        'ExperimentSeed', ...
        'CacheMode'};

    for k = 1:numel(requiredFields)
        if ~isfield(ExperimentOptions, requiredFields{k})
            error('runExperiment:MissingOption', ...
                'Missing ExperimentOptions.%s.', ...
                requiredFields{k});
        end
    end

    % Optional callback for experiment-level progress reporting.
    ProgressCallback = [];

    if isfield(ExperimentOptions, 'ProgressCallback') && ...
            ~isempty(ExperimentOptions.ProgressCallback)

        if ~isa(ExperimentOptions.ProgressCallback, 'function_handle')
            error('runExperiment:InvalidProgressCallback', ...
                'ExperimentOptions.ProgressCallback must be a function handle.');
        end

        ProgressCallback = ExperimentOptions.ProgressCallback;

    end

    NumberOfRuns = ExperimentOptions.NumberOfRuns;

    if ~isnumeric(NumberOfRuns) || ...
            ~isscalar(NumberOfRuns) || ...
            ~isfinite(NumberOfRuns) || ...
            NumberOfRuns < 1 || ...
            NumberOfRuns ~= fix(NumberOfRuns)

        error('runExperiment:InvalidNumberOfRuns', ...
            'NumberOfRuns must be a positive integer.');
    end

    ExperimentSeed = ExperimentOptions.ExperimentSeed;

    if ~isnumeric(ExperimentSeed) || ...
            ~isscalar(ExperimentSeed) || ...
            ~isfinite(ExperimentSeed) || ...
            ExperimentSeed < 0 || ...
            ExperimentSeed > 2^32 - 1 || ...
            ExperimentSeed ~= fix(ExperimentSeed)

        error('runExperiment:InvalidExperimentSeed', ...
            'ExperimentSeed must be an integer between 0 and 2^32-1.');
    end

    %% Normalize selected algorithms

    Algorithms = ExperimentOptions.Algorithms;

    if ischar(Algorithms)
        Algorithms = {Algorithms};
    elseif isstring(Algorithms)
        Algorithms = cellstr(Algorithms(:))';
    end

    if ~iscell(Algorithms) || isempty(Algorithms)
        error('runExperiment:InvalidAlgorithms', ...
            'Algorithms must specify GA, PSO, or both.');
    end

    Selected = false(1, 2);

    for k = 1:numel(Algorithms)

        if ~ischar(Algorithms{k}) || ~isrow(Algorithms{k})
            error('runExperiment:InvalidAlgorithms', ...
                'Each algorithm must be specified as GA or PSO.');
        end

        switch upper(strtrim(Algorithms{k}))
            case 'GA'
                Selected(1) = true;

            case 'PSO'
                Selected(2) = true;

            otherwise
                error('runExperiment:InvalidAlgorithms', ...
                    'Unsupported algorithm: %s.', Algorithms{k});
        end
    end

    % Canonical execution order: GA first, then PSO.
    AlgorithmNames = {'GA', 'PSO'};
    SelectedAlgorithms = AlgorithmNames(Selected);

    %% Validate cache mode

    CacheMode = ExperimentOptions.CacheMode;

    if isstring(CacheMode) && isscalar(CacheMode)
        CacheMode = char(CacheMode);
    end

    if ~ischar(CacheMode) || ~isrow(CacheMode)
        error('runExperiment:InvalidCacheMode', ...
            'CacheMode must be PerRun or SharedExperiment.');
    end

    if strcmpi(CacheMode, 'PerRun')
        CacheMode = 'PerRun';
    elseif strcmpi(CacheMode, 'SharedExperiment')
        CacheMode = 'SharedExperiment';
    else
        error('runExperiment:InvalidCacheMode', ...
            'CacheMode must be PerRun or SharedExperiment.');
    end

    %% Generate all run seeds before any algorithm starts

    SeedStream = RandStream('mt19937ar', ...
        'Seed', ExperimentSeed);

    RunSeeds = zeros(NumberOfRuns, 1);

    for k = 1:NumberOfRuns

        % Generate distinct seeds for independent runs.
        candidateSeed = randi(SeedStream, [0, 2^32 - 1]);

        while any(RunSeeds(1:k-1) == candidateSeed)
            candidateSeed = randi(SeedStream, [0, 2^32 - 1]);
        end

        RunSeeds(k) = candidateSeed;
    end

    %% Initialize experiment metadata

    ExperimentResult = struct();

    ExperimentResult.Metadata.ExperimentID = ...
        char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));

    ExperimentResult.Metadata.DateTime = datetime('now');
    ExperimentResult.Metadata.Version = '1.7.0';

    ExperimentResult.Configuration.NumberOfRuns = NumberOfRuns;
    ExperimentResult.Configuration.Algorithms = SelectedAlgorithms;
    ExperimentResult.Configuration.ExperimentSeed = ExperimentSeed;
    ExperimentResult.Configuration.CacheMode = CacheMode;
    ExperimentResult.Configuration.NS = Config.NS;
    ExperimentResult.Configuration.MaxGen = Config.MaxGen;
    ExperimentResult.Configuration.Pmin = Problem.Pmin;
    ExperimentResult.Configuration.Vmax = Problem.Vmax;
    ExperimentResult.Configuration.NP = Problem.NP;
    ExperimentResult.Configuration.VariablePipes = ...
        Problem.VariablePipes;
    ExperimentResult.Configuration.FixedPipes = ...
        Problem.FixedPipes;

    ExperimentResult.RunSeeds = RunSeeds;
    ExperimentResult.Results = struct();

    %% Initialize experiment-scoped cache if requested

    SharedCache = [];

    if strcmp(CacheMode, 'SharedExperiment')
        [~, SharedCache] = ...
            resolveExperimentCache('SharedExperiment', []);
    end

    %% Execute each selected algorithm

    for a = 1:numel(SelectedAlgorithms)

        Algorithm = SelectedAlgorithms{a};

        RunTemplate = struct( ...
            'Algorithm', '', ...
            'RunIndex', 0, ...
            'Seed', 0, ...
            'Score', NaN, ...
            'Position', [], ...
            'Feasible', false, ...
            'ExecutionTime', NaN, ...
            'Conv', [], ...
            'Status', 'NotStarted', ...
            'ErrorMessage', '');

        Runs = repmat(RunTemplate, NumberOfRuns, 1);

        StopExperiment = false;

        for r = 1:NumberOfRuns

            % Resolve this run's cache before starting the timer.
            [RunCache, SharedCache] = ...
                resolveExperimentCache(CacheMode, SharedCache);

            % Keep base algorithm settings unchanged.
            RunConfig = Config;
            RunConfig.Seed = RunSeeds(r);
            RunConfig.Cache = RunCache;

            % Attach experiment-level progress reporting when requested.
            if ~isempty(ProgressCallback)
                RunConfig.ProgressCallback = ...
                    @(ProgressInfo) reportExperimentProgress( ...
                        ProgressCallback, ProgressInfo, ...
                        Algorithm, r, NumberOfRuns);
            end

            % Initialize this run's result metadata before execution.
            Runs(r).Algorithm = Algorithm;
            Runs(r).RunIndex = r;
            Runs(r).Seed = RunSeeds(r);

            % Time only the algorithm execution.
            timerStart = tic;

            try

                switch Algorithm

                    case 'GA'
                        [Score, Position, Conv, Feasible] = ...
                            runGA(d, Problem, RunConfig);

                    case 'PSO'
                        [Score, Position, Conv, Feasible] = ...
                            runPSO(d, Problem, RunConfig);

                end

                ExecutionTime = toc(timerStart);

                % Store successful run output.
                Runs(r).Score = Score;
                Runs(r).Position = Position;
                Runs(r).Feasible = Feasible;
                Runs(r).ExecutionTime = ExecutionTime;
                Runs(r).Conv = Conv;
                Runs(r).Status = 'Success';

            catch ME

                ExecutionTime = toc(timerStart);

                % Preserve failure information without aborting
                % the remaining sequential runs.
                Runs(r).ExecutionTime = ExecutionTime;
                Runs(r).Status = 'Failed';
                Runs(r).ErrorMessage = ME.message;

                warning('runExperiment:RunFailed', ...
                    '%s run %d/%d failed: %s', ...
                    Algorithm, r, NumberOfRuns, ME.message);

                if isfield(Config, 'Parallel') && ...
                        isfield(Config.Parallel, 'Enabled') && ...
                        Config.Parallel.Enabled

                    StopExperiment = true;
                    break;

                end

            end

        end

        % Complete metadata for runs that were never started.
        for r = 1:numel(Runs)
            if strcmpi(Runs(r).Status, 'NotStarted') && ...
                    Runs(r).RunIndex == 0

                Runs(r).Algorithm = Algorithm;
                Runs(r).RunIndex = r;
                Runs(r).Seed = RunSeeds(r);
                Runs(r).ErrorMessage = ...
                    'Run not started because the experiment stopped after a parallel execution failure.';
            end
        end

        ExperimentResult.Results.(Algorithm).Runs = Runs;

        ExperimentResult.Results.(Algorithm).Statistics = ...
            aggregateExperimentStatistics(Runs);

        ExperimentResult.Results.(Algorithm).ConvergenceData = ...
            aggregateConvergenceData(Runs);

        if StopExperiment

            % Record algorithms that will not be started.
            for nextA = a + 1:numel(SelectedAlgorithms)

                PendingAlgorithm = SelectedAlgorithms{nextA};

                PendingRuns = repmat(RunTemplate, NumberOfRuns, 1);

                for r = 1:NumberOfRuns

                    PendingRuns(r).Algorithm = PendingAlgorithm;
                    PendingRuns(r).RunIndex = r;
                    PendingRuns(r).Seed = RunSeeds(r);
                    PendingRuns(r).Status = 'NotStarted';
                    PendingRuns(r).ErrorMessage = ...
                        'Experiment stopped before this algorithm started.';

                end

                ExperimentResult.Results.(PendingAlgorithm).Runs = ...
                    PendingRuns;

                ExperimentResult.Results.(PendingAlgorithm).Statistics = ...
                    aggregateExperimentStatistics(PendingRuns);

                ExperimentResult.Results.(PendingAlgorithm).ConvergenceData = ...
                    aggregateConvergenceData(PendingRuns);

            end

            break;

        end

    end

end

function reportExperimentProgress( ...
    Callback, ProgressInfo, Algorithm, RunIndex, NumberOfRuns)

    ProgressInfo.Algorithm = Algorithm;
    ProgressInfo.RunIndex = RunIndex;
    ProgressInfo.NumberOfRuns = NumberOfRuns;

    ProgressInfo.RunLabel = sprintf( ...
        '%s run %d/%d', Algorithm, RunIndex, NumberOfRuns);

    Callback(ProgressInfo);

end
