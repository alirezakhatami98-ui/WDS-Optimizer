function Params = buildOptimizationParams( ...
    NS, Pmin, Vmax, FixedPipes, NP, InitialD)

    Params.NS = NS;
    Params.Pmin = Pmin;
    Params.Vmax = Vmax;
    Params.FixedPipes = FixedPipes;
    Params.VariablePipes = setdiff(1:NP, FixedPipes);
    Params.InitialD = InitialD;

end