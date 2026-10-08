function Config = buildAlgorithmConfig(NS, MaxGen)

    Config.NS = NS;
    Config.MaxGen = MaxGen;
    Config.Seed = [];

    Config.GA.Pc = 0.8;
    Config.GA.Pm = 0.03;

    Config.PSO.w = 0.7;
    Config.PSO.c1 = 1.5;
    Config.PSO.c2 = 1.5;

    Config.Parallel.Enabled = false;
    Config.Parallel.NumWorkers = 2;

end