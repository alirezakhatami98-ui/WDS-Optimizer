function testCacheAndEvaluation()

    checkEvaluatePopulation();
    checkExternalCache('GA');
    checkExternalCache('PSO');

end

function checkEvaluatePopulation()

    Env = createTestEnvironment('2loops');
    cleanupObj = onCleanup(Env.Release); %#ok<NASGU>

    d = Env.d;
    Problem = Env.Problem;
    Seq = struct('Enabled', false, 'NumWorkers', 1);

    rng(5);
    NS = 30;
    Pop = randi(numel(Problem.D), numel(Problem.VariablePipes), NS);
    Pop(:, 10) = Pop(:, 3);              % duplicate inside one population

    Cache = createEvaluationCache();
    [c1, v1, f1, Cache] = evaluatePopulation(Pop, Problem, d, Cache, Seq);

    nUnique = size(unique(Pop', 'rows'), 1);
    assert(Cache.Count == nUnique, 'Cache should hold one entry per unique design.');
    assert(c1(10) == c1(3) && v1(10) == v1(3) && f1(10) == f1(3));

    % Second call: every request is a hit and nothing changes
    [c2, v2, f2, Cache] = evaluatePopulation(Pop, Problem, d, Cache, Seq);
    assert(Cache.Count == nUnique);
    assert(isequal(c1, c2) && isequal(v1, v2) && isequal(f1, f2));

    % Each population member agrees with evaluateSolution
    for i = 1:NS
        [c, v, f] = evaluateSolution(Pop(:, i), Problem, d);
        assert(c == c1(i) && v == v1(i) && f == f1(i));
    end

end

function checkExternalCache(alg)

    Env = createTestEnvironment('2loops', 30, 2.5, 8, 5);
    cleanupObj = onCleanup(Env.Release); %#ok<NASGU>

    d = Env.d;
    Problem = Env.Problem;
    Config = Env.Config;

    % Internal (per-run) cache
    [ScoreInt, PosInt] = runAlg(alg, d, Problem, Config);

    % Externally supplied cache: same result, and the cache gets filled
    Cache = createEvaluationCache();
    Config.Cache = Cache;

    [ScoreExt, PosExt] = runAlg(alg, d, Problem, Config);

    assert(ScoreExt == ScoreInt && isequal(PosExt, PosInt), ...
        '%s: result depends on the cache mode.', alg);
    assert(Cache.Count > 0, '%s: external cache was not populated.', alg);

    % Re-running with the same seed and cache adds nothing new
    c0 = Cache.Count;
    [ScoreAgain, ~] = runAlg(alg, d, Problem, Config);

    assert(Cache.Count == c0, '%s: reused cache grew.', alg);
    assert(ScoreAgain == ScoreExt, '%s: reused cache changed the score.', alg);

    % Invalid cache type
    bad = Config;
    bad.Cache = 42;
    expectError(@() runAlg(alg, d, Problem, bad), 'InvalidCache');

end

function [Score, Position] = runAlg(alg, d, Problem, Config)
    switch alg
        case 'GA'
            [Score, Position] = runGA(d, Problem, Config);
        case 'PSO'
            [Score, Position] = runPSO(d, Problem, Config);
    end
end

function expectError(fcn, idPart)
    try
        fcn();
    catch ME
        assert(contains(ME.identifier, idPart), ...
            'Expected error id containing "%s", got "%s".', ...
            idPart, ME.identifier);
        return;
    end
    error('Expected an error containing "%s", but none was thrown.', idPart);
end