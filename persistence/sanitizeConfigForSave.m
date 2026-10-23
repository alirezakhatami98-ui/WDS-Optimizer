function ConfigStatic = sanitizeConfigForSave(Config)
% Keep only static configuration fields for persistence.
% Runtime fields (Seed, Cache, ProgressCallback, CancelCallback)
% are intentionally dropped.

    ConfigStatic = struct();
    ConfigStatic.NS       = Config.NS;
    ConfigStatic.MaxGen   = Config.MaxGen;
    ConfigStatic.GA       = Config.GA;
    ConfigStatic.PSO      = Config.PSO;
    ConfigStatic.Parallel = Config.Parallel;
end