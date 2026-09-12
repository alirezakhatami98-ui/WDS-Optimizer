function [cost, viol, feas] = evaluatePopulation(Pop, Problem, d)

    NS = size(Pop, 2);

    cost = zeros(NS, 1);
    viol = zeros(NS, 1);
    feas = false(NS, 1);

    for i = 1:NS
        [cost(i), viol(i), feas(i)] = ...
            evaluateSolution(Pop(:, i), Problem, d);
    end

end