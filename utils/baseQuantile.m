function q = baseQuantile(x, p)
%BASEQUANTILE Percentile of x at probabilities p (no Statistics Toolbox).
%
%   Equivalent to MATLAB's quantile(x, p) with the default (linear)
%   interpolation method. p can be a scalar or vector.

    x = sort(x(:));
    n = numel(x);
    q = zeros(size(p));
    if n == 0, q(:) = NaN; return; end
    if n == 1, q(:) = x(1); return; end

    for i = 1:numel(p)
        pi = p(i);
        if pi <= 0, q(i) = x(1); continue; end
        if pi >= 1, q(i) = x(end); continue; end

        h = (n - 1) * pi + 1;
        lo = floor(h);
        if lo < 1, lo = 1; end
        if lo >= n, lo = n - 1; end
        frac = h - lo;
        q(i) = x(lo) + frac * (x(lo+1) - x(lo));
    end
end