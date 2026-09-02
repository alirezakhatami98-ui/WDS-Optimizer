function [Score, Position, Conv] = runGA(d, D, NP, L, Din, Cost, Params, MaxGen)

    Problem.d = d;
    Problem.D = D;
    Problem.NP = NP;
    Problem.L = L;
    Problem.Din = Din;

    Problem.Cost = Cost;
    Problem.Pmin = Params.Pmin;
    Problem.Vmax = Params.Vmax;

    Problem.VariablePipes = Params.VariablePipes;
    Problem.InitialD = Params.InitialD;

    NS = Params.NS;
    Pc = 0.8;
    Pm = 0.03;
    ND = numel(D);

    NVar = numel(Problem.VariablePipes);

    Conv = zeros(MaxGen, 1);

    BestCostEver = Inf;
    BestSolEver = [];

    BestViolEver = Inf;
    BestUnfeasibleSol = [];
    BestUnfeasibleCost = Inf;

    Pop = randi(ND, NVar, NS);

    [cost, viol, feas] = evaluatePopulation(Pop, Problem);

    for G = 1:MaxGen

        Fitness = calculateFitness(cost, viol);

        SelectedIdx = selectionRoulette(Fitness, NS);

        MatingPool = Pop(:, SelectedIdx);

        NewPop = MatingPool;

        for i = 1:2:NS-1

            if rand < Pc && NVar > 1

                cp = randi(NVar - 1);

                NewPop(:, i) = ...
                    [MatingPool(1:cp, i);
                     MatingPool(cp+1:end, i+1)];

                NewPop(:, i+1) = ...
                    [MatingPool(1:cp, i+1);
                     MatingPool(cp+1:end, i)];

            end

        end

        for i = 1:NS

            for j = 1:NVar

                if rand < Pm
                    NewPop(j, i) = randi(ND);
                end

            end

        end

        if ~isempty(BestSolEver)

            NewPop(:, 1) = BestSolEver;

        elseif ~isempty(BestUnfeasibleSol)

            NewPop(:, 1) = BestUnfeasibleSol;

        end

        Pop = NewPop;

        [cost, viol, feas] = evaluatePopulation(Pop, Problem);

        feasible_idx = find(feas);

        if ~isempty(feasible_idx)

            [min_c, k] = min(cost(feasible_idx));

            if min_c < BestCostEver

                BestCostEver = min_c;
                BestSolEver = Pop(:, feasible_idx(k));

            end

        end

        [min_v, idx_v] = min(viol);

        if min_v < BestViolEver

            BestViolEver = min_v;
            BestUnfeasibleSol = Pop(:, idx_v);
            BestUnfeasibleCost = cost(idx_v);

        end

        if ~isempty(BestSolEver)
            Conv(G) = BestCostEver;
        else
            Conv(G) = BestUnfeasibleCost;
        end

    end

    if isempty(BestSolEver)

        BestSolEver = BestUnfeasibleSol;
        BestCostEver = BestUnfeasibleCost;

    end

    Score = BestCostEver;

    FullDiameters = Problem.InitialD;

    FullDiameters(Problem.VariablePipes) = ...
        D(BestSolEver);

    Position = FullDiameters';

end