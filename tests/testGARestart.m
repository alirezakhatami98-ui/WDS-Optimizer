function testGARestart()

    Env = createTestEnvironment('2loops', 30, 2.5, 10, 200);
    cleanupObj = onCleanup(Env.Release); %#ok<NASGU>

    d = Env.d;
    Problem = Env.Problem;
    Config = Env.Config;

    % Strong selection pressure collapses the population quickly.
    Config.GA.Selection = 'tournament';

    CacheA = createEvaluationCache();
    Config.Cache = CacheA;
    runGA(d, Problem, Config);

    CacheB = createEvaluationCache();
    Config.Cache = CacheB;
    Config.GA.RestartAfter = 5;
    [ScoreB, PosB, ConvB, FeasB] = runGA(d, Problem, Config);

    % Seeded, so deterministic once it passes; it is a statistical
    % expectation that restarts create more distinct designs.
    assert(CacheB.Count > CacheA.Count, ...
        'Restarts should evaluate more distinct designs.');

    % Score, Position and Feasible must describe the same design.
    ind = zeros(numel(Problem.VariablePipes), 1);
    for k = 1:numel(ind)
        ind(k) = find(Problem.D == PosB(Problem.VariablePipes(k)), 1);
    end

    [c, ~, f] = evaluateSolution(ind, Problem, d);
    assert(c == ScoreB && f == FeasB, ...
        'Returned Score/Feasible do not match the returned Position.');

    assert(ConvB(end) == ScoreB);

    % Invalid option
    Config.GA.RestartAfter = 0;
    try
        runGA(d, Problem, Config);
    catch ME
        assert(contains(ME.identifier, 'InvalidRestartAfter'));
        return;
    end
    error('Expected InvalidRestartAfter error.');

end