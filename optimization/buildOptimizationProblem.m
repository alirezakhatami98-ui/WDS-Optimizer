function Problem = buildOptimizationProblem( ...
    Din, Cost, D, NP, L, InitialD, ...
    FixedPipes, VariablePipes, Pmin, Vmax)

    Problem.Din = Din;
    Problem.Cost = Cost;
    Problem.D = D;

    Problem.NP = NP;
    Problem.L = L;
    Problem.InitialD = InitialD;

    Problem.FixedPipes = FixedPipes;
    Problem.VariablePipes = VariablePipes;

    Problem.Pmin = Pmin;
    Problem.Vmax = Vmax;

end