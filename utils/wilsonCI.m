function [lo, hi] = wilsonCI(k, n, alpha)
%WILSONCI Wilson score interval for a binomial proportion.
%
%   k : successes, n : trials
%   Zero Statistics Toolbox dependency (erfinv-based quantile).

    if nargin < 3 || isempty(alpha), alpha = 0.05; end
    if n <= 0
        lo = NaN; hi = NaN; return;
    end

    z = sqrt(2) * erfinv(1 - alpha);   % == norminv(1 - alpha/2)
    p = k / n;
    denom = 1 + z^2 / n;
    center = (p + z^2 / (2*n)) / denom;
    halfwidth = (z * sqrt(p*(1-p)/n + z^2/(4*n^2))) / denom;
    lo = max(0, center - halfwidth);
    hi = min(1, center + halfwidth);
end