function [lo, hi, bootStats] = bootstrapCI(data, statFcn, alpha, nBoot, seed)
%BOOTSTRAPCI Percentile bootstrap confidence interval for a 1-D sample.
%
%   [lo, hi, bootStats] = bootstrapCI(data, statFcn, alpha, nBoot, seed)
%
%   data    : numeric vector (NaN/Inf dropped)
%   statFcn : function handle on a resampled vector (default @mean)
%   alpha   : significance level (default 0.05, i.e. 95% CI)
%   nBoot   : resample count (default 2000)
%   seed    : PRNG seed (default 42, deterministic per call)
%
%   Deterministic: two calls with same arguments return identical bounds.

    if nargin < 2 || isempty(statFcn), statFcn = @mean; end
    if nargin < 3 || isempty(alpha),   alpha = 0.05; end
    if nargin < 4 || isempty(nBoot),   nBoot = 2000; end
    if nargin < 5 || isempty(seed),    seed = 42; end

    data = data(:);
    data = data(isfinite(data));
    n = numel(data);

    if n < 3
        lo = NaN; hi = NaN; bootStats = [];
        return;
    end

    rs = RandStream('mt19937ar', 'Seed', seed);
    bootStats = zeros(nBoot, 1);
    for b = 1:nBoot
        idx = randi(rs, n, 1);
        bootStats(b) = statFcn(data(idx));
    end

    q = baseQuantile(bootStats, [alpha/2, 1 - alpha/2]);
    lo = q(1);
    hi = q(2);
end