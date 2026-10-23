function [Score, Position, Conv, Feasible] = runGA(d, Problem, Config)

    if ~isempty(Config.Seed)
        rngState = rng;
        cleanupRng = onCleanup(@() rng(rngState));
        rng(Config.Seed);
    end

    % Optional callback for cooperative cancellation.
    CancelCallback = [];

    if isfield(Config, 'CancelCallback') && ...
            ~isempty(Config.CancelCallback)

        if ~isa(Config.CancelCallback, 'function_handle')
            error('runGA:InvalidCancelCallback', ...
                'Config.CancelCallback must be a function handle.');
        end

        CancelCallback = Config.CancelCallback;

    end

    NS = Config.NS;
    MaxGen = Config.MaxGen;

    % Optional callback for live progress reporting.
    ProgressCallback = [];

    if isfield(Config, 'ProgressCallback') && ...
            ~isempty(Config.ProgressCallback)

        if ~isa(Config.ProgressCallback, 'function_handle')
            error('runGA:InvalidProgressCallback', ...
                'Config.ProgressCallback must be a function handle.');
        end

        ProgressCallback = Config.ProgressCallback;

    end

    % Report progress at approximately 50 points or fewer,
    % while always including the first and last generations.
    ProgressInterval = max(1, ceil(MaxGen / 50));

    ProgressCallbackFailed = false;

    Pc = Config.GA.Pc;
    Pm = Config.GA.Pm;

    selectionMethod = 'roulette';
    if isfield(Config.GA, 'Selection') && ~isempty(Config.GA.Selection)
        selectionMethod = lower(Config.GA.Selection);
    end

    if ~ismember(selectionMethod, {'roulette', 'tournament'})
        error('runGA:InvalidSelection', ...
            'Config.GA.Selection must be ''roulette'' or ''tournament''.');
    end

    tournamentSize = 3;
    if isfield(Config.GA, 'TournamentSize') && ~isempty(Config.GA.TournamentSize)
        tournamentSize = Config.GA.TournamentSize;
    end

    RestartAfter = [];

    if isfield(Config.GA, 'RestartAfter') && ~isempty(Config.GA.RestartAfter)

        RestartAfter = Config.GA.RestartAfter;

        if ~isnumeric(RestartAfter) || ~isscalar(RestartAfter) || ...
                RestartAfter < 1 || RestartAfter ~= floor(RestartAfter)
            error('runGA:InvalidRestartAfter', ...
                'Config.GA.RestartAfter must be a positive integer or empty.');
        end

    end

    ND = numel(Problem.D);
    NVar = numel(Problem.VariablePipes);

    Conv = zeros(MaxGen, 1);

    BestCostEver = Inf;
    BestSolEver = [];
    BestViolEver = Inf;

    BestUnfeasibleSol = [];
    BestUnfeasibleCost = Inf;

    % Best solution over all restarts (the result of the run).
    GlobalSol = [];
    GlobalCost = Inf;
    GlobalViol = Inf;

    StagnationCount = 0;

    Pop = randi(ND, NVar, NS);

    % Use a supplied cache when available; otherwise create a per-run cache.
    if isfield(Config, 'Cache') && isa(Config.Cache, 'containers.Map')
        Cache = Config.Cache;
    else
        if isfield(Config, 'Cache') && ~isempty(Config.Cache)
            error('runGA:InvalidCache', ...
                'Config.Cache must be a containers.Map object.');
        end
        Cache = createEvaluationCache();
    end

    [cost, viol, ~, Cache] = ...
        evaluatePopulation( ...
            Pop, Problem, d, Cache, Config.Parallel);

    for G = 1:MaxGen

        % Check for a cancellation request at a safe checkpoint.
        if ~isempty(CancelCallback) && CancelCallback()
            error('runGA:Cancelled', ...
                'GA execution was cancelled by the user.');
        end

        switch selectionMethod
            case 'tournament'
                SelectedIdx = selectionTournament( ...
                    cost, viol, NS, tournamentSize);
            otherwise
                Fitness = calculateFitness(cost, viol);
                SelectedIdx = selectionRoulette(Fitness, NS);
        end
        MatingPool = Pop(:, SelectedIdx);

        NewPop = MatingPool;

        for i = 1:2:NS-1
            if rand < Pc && NVar > 1

                cp = randi(NVar - 1);

                NewPop(:, i) = ...
                    [MatingPool(1:cp, i);
                     MatingPool(cp+1:end, i+1)];

                NewPop(:, i+1) = ...
                    [MatingPool(1:cp, i+1);
                     MatingPool(cp+1:end, i)];

            end
        end

        for i = 1:NS
            for j = 1:NVar

                if rand < Pm
                    NewPop(j, i) = randi(ND);
                end

            end
        end

        if ~isempty(BestSolEver)

            NewPop(:, 1) = BestSolEver;

        elseif ~isempty(BestUnfeasibleSol)

            NewPop(:, 1) = BestUnfeasibleSol;

        end

        Pop = NewPop;

        [cost, viol, feas, Cache] = ...
            evaluatePopulation( ...
                Pop, Problem, d, Cache, Config.Parallel);

        [PrevEpochCost, PrevEpochViol] = epochBest( ...
            BestSolEver, BestCostEver, BestUnfeasibleCost, BestViolEver);
        
        feasible_idx = find(feas);

        if ~isempty(feasible_idx)

            [min_c, k] = min(cost(feasible_idx));

            if min_c < BestCostEver

                BestCostEver = min_c;
                BestSolEver = Pop(:, feasible_idx(k));

            end
        end

        [min_v, idx_v] = min(viol);

        if min_v < BestViolEver

            BestViolEver = min_v;
            BestUnfeasibleSol = Pop(:, idx_v);
            BestUnfeasibleCost = cost(idx_v);

        end

        [EpochCost, EpochViol] = epochBest( ...
            BestSolEver, BestCostEver, BestUnfeasibleCost, BestViolEver);

        if isBetterSolution(EpochCost, EpochViol, PrevEpochCost, PrevEpochViol)
            StagnationCount = 0;
        else
            StagnationCount = StagnationCount + 1;
        end

        if isBetterSolution(EpochCost, EpochViol, GlobalCost, GlobalViol)

            if ~isempty(BestSolEver)
                GlobalSol = BestSolEver;
            else
                GlobalSol = BestUnfeasibleSol;
            end

            GlobalCost = EpochCost;
            GlobalViol = EpochViol;

        end

        Conv(G) = GlobalCost;

        % Report selected generations to the optional callback.
        ShouldReportProgress = ...
            (G == 1) || ...
            (mod(G - 1, ProgressInterval) == 0) || ...
            (G == MaxGen);

        if ~isempty(ProgressCallback) && ...
                ~ProgressCallbackFailed && ShouldReportProgress

            ProgressInfo = struct( ...
                'Algorithm', 'GA', ...
                'Generation', G, ...
                'MaxGenerations', MaxGen, ...
                'BestCost', Conv(G), ...
                'Feasible', (GlobalViol == 0), ...
                'Convergence', Conv(1:G));

            try

                ProgressCallback(ProgressInfo);

            catch ME

                % A monitoring failure must not stop optimization.
                warning('runGA:ProgressCallbackFailed', ...
                    'Progress reporting disabled after an error: %s', ...
                    ME.message);

                ProgressCallbackFailed = true;

            end

        end

        % Restart the population when the search has stagnated.
        if ~isempty(RestartAfter) && ...
                StagnationCount >= RestartAfter && G < MaxGen

            Pop = randi(ND, NVar, NS);

            [cost, viol, ~, Cache] = evaluatePopulation( ...
                Pop, Problem, d, Cache, Config.Parallel);

            % A new, independent epoch: elitism uses only its own best.
            BestCostEver = Inf;
            BestSolEver = [];
            BestViolEver = Inf;

            BestUnfeasibleSol = [];
            BestUnfeasibleCost = Inf;

            StagnationCount = 0;

        end

    end

    Feasible = (GlobalViol == 0);
    Score = GlobalCost;

    FullDiameters = Problem.InitialD;
    FullDiameters(Problem.VariablePipes) = ...
        Problem.D(GlobalSol);

    Position = FullDiameters';

end

function [c, v] = epochBest(BestSol, BestCost, BestUnfeasibleCost, BestViol)

    if ~isempty(BestSol)
        c = BestCost;
        v = 0;
    else
        c = BestUnfeasibleCost;
        v = BestViol;
    end

end