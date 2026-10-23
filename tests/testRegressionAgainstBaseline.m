function testRegressionAgainstBaseline()

    root = fileparts(fileparts(mfilename('fullpath')));

    for alg = {'GA', 'PSO'}

        f = fullfile(root, 'studies', 'results', 'baseline', ...
            sprintf('2loops_%s.mat', alg{1}));

        if ~isfile(f)
            error('WDS:TestSkipped', 'Baseline results not found: %s', f);
        end

        L = load(f);
        Stored = L.ExperimentResult.Results.(alg{1}).Runs(1);

        Env = createTestEnvironment('2loops', [], [], ...
            L.Settings.NS, L.Settings.MaxGen);
        cleanupObj = onCleanup(Env.Release); %#ok<NASGU>

        Config = Env.Config;
        Config.Seed = Stored.Seed;
        Config.GA = L.Settings.GAEffective;
        Config.PSO = L.Settings.PSOEffective;

        switch alg{1}
            case 'GA'
                [Score, Position] = runGA(Env.d, Env.Problem, Config);
            case 'PSO'
                [Score, Position] = runPSO(Env.d, Env.Problem, Config);
        end

        assert(Score == Stored.Score && isequal(Position, Stored.Position), ...
            '%s: default behaviour changed (stored %.6g, now %.6g).', ...
            alg{1}, Stored.Score, Score);

        clear cleanupObj;

    end

end