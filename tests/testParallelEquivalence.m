function testParallelEquivalence()

    if ~license('test', 'Distrib_Computing_Toolbox')
        error('WDS:TestSkipped', 'Parallel Computing Toolbox is not available.');
    end

    Env = createTestEnvironment('2loops', 30, 2.5, 20, 10);
    cleanupEnv = onCleanup(Env.Release); %#ok<NASGU>

    poolExisted = ~isempty(gcp('nocreate'));
    cleanupPool = onCleanup(@() shutdownParallel(poolExisted)); %#ok<NASGU>

    d = Env.d;
    Problem = Env.Problem;
    Config = Env.Config;
    numWorkers = 2;

    initializeParallelHydraulics(Env.TempInp, numWorkers);

    % Population evaluation
    rng(21);
    Pop = randi(numel(Problem.D), numel(Problem.VariablePipes), 100);

    Seq = struct('Enabled', false, 'NumWorkers', numWorkers);
    Par = struct('Enabled', true, 'NumWorkers', numWorkers);

    [cS, vS, fS] = evaluatePopulation(Pop, Problem, d, createEvaluationCache(), Seq);
    [cP, vP, fP] = evaluatePopulation(Pop, Problem, d, createEvaluationCache(), Par);

    assert(isequal(cS, cP) && isequal(vS, vP) && isequal(fS, fP), ...
        'Parallel population evaluation differs from sequential.');

    % Whole optimizations
    ConfigSeq = Config;
    ConfigSeq.Parallel.Enabled = false;

    ConfigPar = Config;
    ConfigPar.Parallel.Enabled = true;
    ConfigPar.Parallel.NumWorkers = numWorkers;

    [S1, P1] = runGA(d, Problem, ConfigSeq);
    [S2, P2] = runGA(d, Problem, ConfigPar);
    assert(S1 == S2 && isequal(P1, P2), 'GA: parallel differs from sequential.');

    [S1, P1] = runPSO(d, Problem, ConfigSeq);
    [S2, P2] = runPSO(d, Problem, ConfigPar);
    assert(S1 == S2 && isequal(P1, P2), 'PSO: parallel differs from sequential.');

end

function shutdownParallel(poolExisted)

    try
        cleanupParallelHydraulics();
    catch
    end

    if ~poolExisted
        p = gcp('nocreate');
        if ~isempty(p)
            delete(p);
        end
    end

end