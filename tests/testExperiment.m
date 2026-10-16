function testExperiment()

    Env = createTestEnvironment('2loops', 30, 2.5, 6, 3);
    cleanupObj = onCleanup(Env.Release); %#ok<NASGU>

    d = Env.d;
    Problem = Env.Problem;
    Config = Env.Config;

    Opt = struct('NumberOfRuns', 2, 'Algorithms', {{'GA', 'PSO'}}, ...
        'ExperimentSeed', 12345, 'CacheMode', 'PerRun');

    R1 = runExperiment(d, Problem, Config, Opt);

    for fld = {'Metadata', 'Configuration', 'RunSeeds', 'Results'}
        assert(isfield(R1, fld{1}), 'Missing field %s.', fld{1});
    end

    assert(numel(unique(R1.RunSeeds)) == numel(R1.RunSeeds));
    assert(strcmp(R1.Configuration.CacheMode, 'PerRun'));

    for a = {'GA', 'PSO'}

        Runs = R1.Results.(a{1}).Runs;

        assert(numel(Runs) == 2);
        assert(all(strcmp({Runs.Status}, 'Success')));
        assert(all(isfinite([Runs.Score])));
        assert(all([Runs.ExecutionTime] >= 0));

        for k = 1:numel(Runs)
            assert(strcmp(Runs(k).Algorithm, a{1}));
            assert(Runs(k).RunIndex == k);
        end

    end

    GARuns = R1.Results.GA.Runs;
    for k = 1:numel(GARuns)
        assert(GARuns(k).Seed == R1.RunSeeds(k));
    end

    % Same experiment seed -> identical results
    R2 = runExperiment(d, Problem, Config, Opt);
    assertSameResults(R1, R2, 'repeat run');

    % The cache mode must change speed only, never the results
    Opt.CacheMode = 'SharedExperiment';
    R3 = runExperiment(d, Problem, Config, Opt);
    assertSameResults(R1, R3, 'SharedExperiment');

end

function assertSameResults(A, B, label)

    for a = {'GA', 'PSO'}

        RA = A.Results.(a{1}).Runs;
        RB = B.Results.(a{1}).Runs;

        assert(isequal([RA.Score], [RB.Score]), ...
            '%s: %s scores differ (%s).', a{1}, 'final', label);

        assert(isequal({RA.Position}, {RB.Position}), ...
            '%s: positions differ (%s).', a{1}, label);

    end

end