function [H, p, df] = kruskalWallisH(groups)
%KRUSKALWALLISH Kruskal-Wallis H test (>2 independent samples).
%
%   groups : cell array of numeric vectors
%   Zero Statistics Toolbox dependency (gammainc-based p-value).

    groups = groups(:);
    k = numel(groups);
    for i = 1:k
        groups{i} = groups{i}(isfinite(groups{i}));
    end
    N = sum(cellfun(@numel, groups));

    if k < 2 || N < 3
        H = NaN; p = NaN; df = 0;
        return;
    end

    combined = vertcat(groups{:});
    groupId = zeros(N, 1);
    pos = 1;
    for i = 1:k
        ni = numel(groups{i});
        groupId(pos:pos+ni-1) = i;
        pos = pos + ni;
    end

    [~, sortIdx] = sort(combined);
    ranks = zeros(N, 1);
    ranks(sortIdx) = 1:N;

    uniqueVals = unique(combined);
    for i = 1:numel(uniqueVals)
        tieIdx = find(combined == uniqueVals(i));
        if numel(tieIdx) > 1
            ranks(tieIdx) = mean(ranks(tieIdx));
        end
    end

    H = 0;
    for i = 1:k
        ni = sum(groupId == i);
        if ni > 0
            Rbar = mean(ranks(groupId == i));
            H = H + ni * Rbar^2;
        end
    end
    H = (12 / (N * (N + 1))) * H - 3 * (N + 1);

    df = k - 1;
    p  = 1 - gammainc(H/2, df/2);
end