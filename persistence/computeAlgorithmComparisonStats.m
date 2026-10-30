function Stats = computeAlgorithmComparisonStats(RunsA, RunsB)
%COMPUTEALGORITHMCOMPARISONSTATS Statistical test between two run sets.
%
% Uses feasible successful runs only for cost statistics.

    scoresA = extractFeasibleScores(RunsA);
    scoresB = extractFeasibleScores(RunsB);

    Stats.N_A = numel(scoresA);
    Stats.N_B = numel(scoresB);
    Stats.Median_A = medianOrNaN(scoresA);
    Stats.Median_B = medianOrNaN(scoresB);
    Stats.Mean_A   = meanOrNaN(scoresA);
    Stats.Mean_B   = meanOrNaN(scoresB);

    [~, Stats.PValue] = mannWhitneyU(scoresA, scoresB);
    [Stats.CohensD, Stats.EffectSize] = cohensD(scoresA, scoresB);

    [Stats.DeltaMedianCI_Low, Stats.DeltaMedianCI_High] = ...
        twoSampleBootstrapDiff(scoresA, scoresB, @median, 0.05, 2000, 42);

    Stats.Significant = isfinite(Stats.PValue) && Stats.PValue < 0.05;
end

function s = extractFeasibleScores(Runs)
    if isempty(Runs), s = []; return; end
    Ok = strcmp({Runs.Status}, 'Success') & ...
        logical([Runs.Feasible]) & isfinite([Runs.Score]);
    s = [Runs(Ok).Score]';
end

function m = medianOrNaN(v)
    if isempty(v), m = NaN; else, m = median(v); end
end

function m = meanOrNaN(v)
    if isempty(v), m = NaN; else, m = mean(v); end
end

function [lo, hi] = twoSampleBootstrapDiff(x, y, statFcn, alpha, nBoot, seed)
    x = x(:); y = y(:);
    x = x(isfinite(x)); y = y(isfinite(y));
    nx = numel(x); ny = numel(y);
    if nx < 2 || ny < 2
        lo = NaN; hi = NaN; return;
    end
    rs = RandStream('mt19937ar', 'Seed', seed);
    deltas = zeros(nBoot, 1);
    for b = 1:nBoot
        xi = x(randi(rs, nx, 1));
        yi = y(randi(rs, ny, 1));
        deltas(b) = statFcn(xi) - statFcn(yi);
    end
    q = baseQuantile(deltas, [alpha/2, 1 - alpha/2]);
    lo = q(1); hi = q(2);
end