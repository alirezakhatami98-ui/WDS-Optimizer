function [U, p, z] = mannWhitneyU(x, y)
%MANNWHITNEYU Two-sided Mann-Whitney U test (normal approximation).
%
%   [U, p, z] = mannWhitneyU(x, y)
%
%   Tied values receive the average rank. Continuity correction applied.
%   Returns NaN if min(numel(x), numel(y)) < 5 (normal approx unreliable).
%
%   Zero Statistics Toolbox dependency (erfc-based p-value).

    x = x(:); y = y(:);
    x = x(isfinite(x)); y = y(isfinite(y));
    n1 = numel(x); n2 = numel(y);

    if n1 < 5 || n2 < 5
        U = NaN; p = NaN; z = NaN;
        return;
    end

    combined = [x; y];
    N = n1 + n2;

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

    R1 = sum(ranks(1:n1));
    R2 = sum(ranks(n1+1:end));
    U1 = R1 - n1*(n1+1)/2;
    U2 = R2 - n2*(n2+1)/2;
    U = min(U1, U2);

    mu_U    = n1 * n2 / 2;
    sigma_U = sqrt(n1 * n2 * (N + 1) / 12);

    if sigma_U == 0
        U = NaN; p = NaN; z = NaN;
        return;
    end

    absZ = max(0, (abs(U - mu_U) - 0.5) / sigma_U);
    p = erfc(absZ / sqrt(2));
    if p > 1, p = 1; end
    z = (U - mu_U) / sigma_U;
end