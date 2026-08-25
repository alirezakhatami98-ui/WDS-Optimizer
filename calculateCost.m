function cost = calculateCost(FullD, VariablePipes, Din, Cost, L)

    cost = 0;

    for i = VariablePipes
        [~, idx] = min(abs((Din * 25.4) - FullD(i)));
        cost = cost + L(i) * Cost(idx);
    end

end