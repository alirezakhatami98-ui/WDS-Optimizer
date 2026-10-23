function testPSORestart()

    Env = createTestEnvironment('2loops', 30, 2.5, 10, 200);
    cleanupObj = onCleanup(Env.Release); %#ok<NASGU>

    d = Env.d;
    Problem = Env.Problem;
    Config = Env.Config;

    % Without restart: the swarm collapses, the cache stops growing.
    CacheA = createEvaluationCache();
    Config.Cache = CacheA;
    [ScoreA, PosA] = runPSO(d, Problem, Config);

    % With restart: stagnation triggers fresh swarms, more distinct designs.
    CacheB = createEvaluationCache();
    Config.Cache = CacheB;
    Config.PSO.RestartAfter = 5;
    [ScoreB, PosB, ConvB, FeasB] = runPSO(d, Problem, Config);

    assert(CacheB.Count > CacheA.Count, ...
        'Restarts should evaluate more distinct designs than a collapsed swarm.');

    % Score, Position and Feasible must describe the same design.
    ind = zeros(numel(Problem.VariablePipes), 1);
    for k = 1:numel(ind)
        ind(k) = find(Problem.D == PosB(Problem.VariablePipes(k)), 1);
    end

    [c, ~, f] = evaluateSolution(ind, Problem, d);

    assert(c == ScoreB && f == FeasB, ...
        'Returned Score/Feasible do not match the returned Position.');

    % The convergence curve never ends worse than the returned score.
    assert(ConvB(end) == ScoreB);

    % Invalid option
    Config.PSO.RestartAfter = 0;
    try
        runPSO(d, Problem, Config);
    catch ME
        assert(contains(ME.identifier, 'InvalidRestartAfter'));
        return;
    end
    error('Expected InvalidRestartAfter error.');

end