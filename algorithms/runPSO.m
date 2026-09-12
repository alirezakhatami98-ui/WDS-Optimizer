function [Score, Position, Conv] = runPSO(d, Problem, Config)

    N = Config.NS;
    MaxGen = Config.MaxGen;
    ND = numel(Problem.D);
    NVar = numel(Problem.VariablePipes);

    w = 0.7;
    c1 = 1.5;
    c2 = 1.5;

    X = randi(ND, NVar, N);
    V = zeros(NVar, N);

    PBestX = X;
    PBestCost = Inf(1, N);
    PBestViol = Inf(1, N);

    GBestX = [];
    GBestCost = Inf;
    GBestViol = Inf;

    Conv = zeros(MaxGen, 1);

    for G = 1:MaxGen

        X_discrete = round(X);
        X_discrete = max(1, min(ND, X_discrete));

        [cost, viol, feas] = evaluatePopulation(X_discrete, Problem, d);

        for i = 1:N

            if (feas(i) && cost(i) < PBestCost(i)) || ...
               (~feas(i) && viol(i) < PBestViol(i))

                PBestCost(i) = cost(i);
                PBestViol(i) = viol(i);
                PBestX(:, i) = X_discrete(:, i);

            end

            if (feas(i) && cost(i) < GBestCost) || ...
               (~feas(i) && viol(i) < GBestViol)

                GBestCost = cost(i);
                GBestViol = viol(i);
                GBestX = X_discrete(:, i);

            end

        end

        for i = 1:N

            r1 = rand(NVar, 1);
            r2 = rand(NVar, 1);

            V(:, i) = ...
                w * V(:, i) + ...
                c1 * r1 .* (PBestX(:, i) - X(:, i)) + ...
                c2 * r2 .* (GBestX - X(:, i));

            X(:, i) = X(:, i) + V(:, i);

        end

        Conv(G) = GBestCost;

    end

    Score = GBestCost;

    FullDiameters = Problem.InitialD;
    FullDiameters(Problem.VariablePipes) = ...
        Problem.D(GBestX);

    Position = FullDiameters';

end