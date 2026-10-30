function [d, interpretation] = cohensD(x, y)
%COHENSD Cohen's d effect size between two independent samples.
%
%   d = (mean(x) - mean(y)) / pooled_std
%   interpretation: 'negligible' (<0.2), 'small' (0.2-0.5),
%                   'medium' (0.5-0.8), 'large' (>=0.8)

    x = x(:); y = y(:);
    x = x(isfinite(x)); y = y(isfinite(y));
    n1 = numel(x); n2 = numel(y);

    if n1 < 2 || n2 < 2
        d = NaN; interpretation = 'N/A';
        return;
    end

    s1 = std(x);
    s2 = std(y);
    pooled = sqrt(((n1-1)*s1^2 + (n2-1)*s2^2) / (n1 + n2 - 2));

    if pooled == 0 || ~isfinite(pooled)
        d = NaN; interpretation = 'N/A';
        return;
    end

    d = (mean(x) - mean(y)) / pooled;
    ad = abs(d);
    if ad < 0.2
        interpretation = 'negligible';
    elseif ad < 0.5
        interpretation = 'small';
    elseif ad < 0.8
        interpretation = 'medium';
    else
        interpretation = 'large';
    end
end