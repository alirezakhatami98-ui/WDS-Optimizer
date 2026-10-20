function testPSOProgressCallback()

    Env = createTestEnvironment('2loops', 30, 2.5, 6, 7);
    cleanupObj = onCleanup(Env.Release); %#ok<NASGU>

    d = Env.d;
    Problem = Env.Problem;
    Config = Env.Config;

    Reports = struct( ...
        'Algorithm', {}, ...
        'Generation', {}, ...
        'MaxGenerations', {}, ...
        'BestCost', {}, ...
        'Feasible', {}, ...
        'Convergence', {});

    Config.ProgressCallback = @captureProgress;

    [Score, Position, Conv, Feasible] = runPSO(d, Problem, Config);

    MaxGen = Config.MaxGen;
    ProgressInterval = max(1, ceil(MaxGen / 50));

    Generations = [Reports.Generation];

    assert(~isempty(Reports), ...
        'No progress reports were received.');

    assert(Generations(1) == 1, ...
        'The first generation was not reported.');

    assert(Generations(end) == MaxGen, ...
        'The last generation was not reported.');

    Expected = unique([1:ProgressInterval:MaxGen, MaxGen]);

    assert(isequal(Generations, Expected), ...
        'Unexpected progress reporting schedule.');

    for k = 1:numel(Reports)

        R = Reports(k);

        assert(strcmp(R.Algorithm, 'PSO'), ...
            'Incorrect algorithm name in report.');

        assert(R.Generation >= 1 && ...
               R.Generation <= MaxGen, ...
            'Generation number is out of range.');

        assert(R.MaxGenerations == MaxGen, ...
            'Incorrect MaxGenerations value.');

        assert(isfinite(R.BestCost), ...
            'Reported BestCost must be finite.');

        assert(islogical(R.Feasible) && isscalar(R.Feasible), ...
            'Reported Feasible must be a logical scalar.');

        assert(isnumeric(R.Convergence) && ...
               isvector(R.Convergence), ...
            'Convergence must be a numeric vector.');

        assert(numel(R.Convergence) == R.Generation, ...
            'Convergence length must match the reported generation.');

        assert(all(isfinite(R.Convergence)), ...
            'Convergence contains non-finite values.');

        assert(R.Convergence(end) == R.BestCost, ...
            'Final convergence value must match BestCost.');

    end

    assert(isfinite(Score), 'Score must be finite.');

    assert(numel(Conv) == MaxGen, ...
        'Conv has an unexpected length.');

    assert(all(isfinite(Conv)), ...
        'Conv contains non-finite values.');

    assert(islogical(Feasible) && isscalar(Feasible), ...
        'Feasible must be a logical scalar.');

    assert(numel(Position) == Problem.NP, ...
        'Position has an unexpected length.');

    fprintf('testPSOProgressCallback passed: %d reports received.\n', ...
        numel(Reports));

    function captureProgress(ProgressInfo)
        Reports(end + 1) = ProgressInfo;
    end

end