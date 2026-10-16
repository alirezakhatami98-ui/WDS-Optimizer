function cost = calculateCostFromIndices(ind, VariablePipes, Cost, L)
% Cost of the variable pipes only.
% ind(j) is the diameter-option index of pipe VariablePipes(j).
% Cost(k) is the unit cost of diameter option k.

    if numel(ind) ~= numel(VariablePipes)
        error('calculateCostFromIndices:SizeMismatch', ...
            'ind has %d elements but VariablePipes has %d.', ...
            numel(ind), numel(VariablePipes));
    end

    Lv = L(VariablePipes(:));
    Lv = Lv(:);

    Cv = Cost(ind(:));
    Cv = Cv(:);

    cost = sum(Lv .* Cv);

end