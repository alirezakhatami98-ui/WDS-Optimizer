function [cost, viol, feas] = evaluateSolution(ind, Problem)

    d = Problem.d;
    D = Problem.D;
    NP = Problem.NP;
    L = Problem.L;
    Din = Problem.Din;
    Cost = Problem.Cost;
    Pmin = Problem.Pmin;
    Vmax = Problem.Vmax;

    FullD = Problem.InitialD;
    FullD(Problem.VariablePipes) = D(ind);

    [Pj, Vpipes] = runHydraulicSimulation(d, NP, FullD);

    cost = calculateCost(FullD, Problem.VariablePipes, Din, Cost, L);

    [viol, feas] = checkConstraints(Pj, Vpipes, Pmin, Vmax);

end