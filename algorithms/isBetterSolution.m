function tf = isBetterSolution(costA, violA, costB, violB)
% Feasibility rules: feasible beats infeasible; two feasible -> lower
% cost; two infeasible -> lower violation.

    feasA = (violA == 0);
    feasB = (violB == 0);

    if feasA && feasB
        tf = costA < costB;
    elseif feasA ~= feasB
        tf = feasA;
    else
        tf = violA < violB;
    end

end