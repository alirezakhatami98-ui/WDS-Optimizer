function [Score, Position, Conv, Feasible] = runPSO(d, Problem, Config)

    if ~isempty(Config.Seed)
        rngState = rng;
        cleanupRng = onCleanup(@() rng(rngState));
        rng(Config.Seed);
    end

    N = Config.NS;
    MaxGen = Config.MaxGen;

    % Optional callback for live progress reporting.
    ProgressCallback = [];

    if isfield(Config, 'ProgressCallback') && ...
            ~isempty(Config.ProgressCallback)

        if ~isa(Config.ProgressCallback, 'function_handle')
            error('runPSO:InvalidProgressCallback', ...
                'Config.ProgressCallback must be a function handle.');
        end

        ProgressCallback = Config.ProgressCallback;

    end

    % Report progress at approximately 50 points or fewer,
    % while always including the first and last generations.
    ProgressInterval = max(1, ceil(MaxGen / 50));

    ProgressCallbackFailed = false;

    ND = numel(Problem.D);
    NVar = numel(Problem.VariablePipes);

    w  = Config.PSO.w;
    c1 = Config.PSO.c1;
    c2 = Config.PSO.c2;

    X = randi(ND, NVar, N);
    V = zeros(NVar, N);

    PBestX = X;
    PBestCost = Inf(1, N);
    PBestViol = Inf(1, N);

    % Use a supplied cache when available; otherwise create a per-run cache.
    if isfield(Config, 'Cache') && isa(Config.Cache, 'containers.Map')
        Cache = Config.Cache;
    else
        if isfield(Config, 'Cache') && ~isempty(Config.Cache)
            error('runPSO:InvalidCache', ...
                'Config.Cache must be a containers.Map object.');
        end
        Cache = createEvaluationCache();
    end

    GBestX = [];
    GBestCost = Inf;
    GBestViol = Inf;

    Conv = zeros(MaxGen, 1);

    for G = 1:MaxGen

        X_discrete = round(X);
        X_discrete = max(1, min(ND, X_discrete));

        [cost, viol, feas, Cache] = ...
            evaluatePopulation( ...
                X_discrete, Problem, d, Cache, Config.Parallel);

        for i = 1:N

            if feas(i)

                if PBestViol(i) > 0 || cost(i) < PBestCost(i)

                    PBestCost(i) = cost(i);
                    PBestViol(i) = viol(i);
                    PBestX(:, i) = X_discrete(:, i);

                end

            else

                if PBestViol(i) > 0 && viol(i) < PBestViol(i)

                    PBestCost(i) = cost(i);
                    PBestViol(i) = viol(i);
                    PBestX(:, i) = X_discrete(:, i);

                end

            end


            if feas(i)

                if GBestViol > 0 || cost(i) < GBestCost

                    GBestCost = cost(i);
                    GBestViol = viol(i);
                    GBestX = X_discrete(:, i);

                end

            else

                if GBestViol > 0 && viol(i) < GBestViol

                    GBestCost = cost(i);
                    GBestViol = viol(i);
                    GBestX = X_discrete(:, i);

                end

            end

        end

        for i = 1:N

            r1 = rand(NVar, 1);
            r2 = rand(NVar, 1);

            V(:, i) = ...
                w * V(:, i) + ...
                c1 * r1 .* (PBestX(:, i) - X(:, i)) + ...
                c2 * r2 .* (GBestX - X(:, i));

            X(:, i) = X(:, i) + V(:, i);

        end

        Conv(G) = GBestCost;

        % Report selected generations to the optional callback.
        ShouldReportProgress = ...
            (G == 1) || ...
            (mod(G - 1, ProgressInterval) == 0) || ...
            (G == MaxGen);

        if ~isempty(ProgressCallback) && ...
                ~ProgressCallbackFailed && ShouldReportProgress

            ProgressInfo = struct( ...
                'Algorithm', 'PSO', ...
                'Generation', G, ...
                'MaxGenerations', MaxGen, ...
                'BestCost', Conv(G), ...
                'Feasible', (GBestViol == 0), ...
                'Convergence', Conv(1:G));

            try
                ProgressCallback(ProgressInfo);
            catch ME
                % A monitoring failure must not stop optimization.
                warning('runPSO:ProgressCallbackFailed', ...
                    'Progress reporting disabled after an error: %s', ...
                    ME.message);
                ProgressCallbackFailed = true;
            end
        end

    end

    Score = GBestCost;
    Feasible = (GBestViol == 0);

    FullDiameters = Problem.InitialD;
    FullDiameters(Problem.VariablePipes) = ...
        Problem.D(GBestX);
    Position = FullDiameters';

end