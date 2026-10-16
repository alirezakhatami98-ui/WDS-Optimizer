function [cost, viol, feas] = evaluateSolution(ind, Problem, d)

    D = Problem.D;
    NP = Problem.NP;
    Pmin = Problem.Pmin;
    Vmax = Problem.Vmax;

    FullD = Problem.InitialD;
    FullD(Problem.VariablePipes) = D(ind);

    [Pj, Vpipes, Converged] = runHydraulicSimulation( ...
        d, NP, FullD, Problem.JunctionIndices);

    cost = calculateCostFromIndices( ...
        ind, Problem.VariablePipes, Problem.Cost, Problem.L);

    [viol, feas] = checkConstraints( ...
        Pj, Vpipes, Pmin, Vmax, Converged);

end