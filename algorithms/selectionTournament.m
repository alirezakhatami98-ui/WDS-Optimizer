function idx = selectionTournament(cost, viol, NS, k)
% Tournament selection with feasibility rules (Deb):
%   feasible beats infeasible; two feasible -> lower cost wins;
%   two infeasible -> lower violation wins.

    if nargin < 4 || isempty(k)
        k = 3;
    end

    cost = cost(:);
    viol = viol(:);
    N = numel(cost);

    idx = zeros(1, NS);

    for s = 1:NS

        cand = randi(N, 1, k);
        best = cand(1);

        for j = 2:k
            if isBetter(cand(j), best, cost, viol)
                best = cand(j);
            end
        end

        idx(s) = best;

    end

end

function tf = isBetter(a, b, cost, viol)

    feasA = (viol(a) == 0);
    feasB = (viol(b) == 0);

    if feasA && feasB
        tf = cost(a) < cost(b);
    elseif feasA ~= feasB
        tf = feasA;
    else
        tf = viol(a) < viol(b);
    end

end