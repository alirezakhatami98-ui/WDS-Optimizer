function [Data, SectionRows] = buildComparisonSummaryData(ExpA, ExpB, NameA, NameB)
%BUILDCOMPARISONSUMMARYDATA Build a cell array for the comparison table.
%
%   [Data, SectionRows] = buildComparisonSummaryData(ExpA, ExpB, NameA, NameB)
%
%   Data is an N-by-4 cell array:
%       Metric | Experiment A | Experiment B | Delta (B - A)
%
%   SectionRows is a logical vector marking section-header rows (caller
%   should apply bold styling to those rows).

    Data = cell(0, 4);
    SectionRows = false(0, 1);

    % ---- Configuration ----
    addSection('Configuration');
    addRow('Experiment ID', ...
        ExpA.ExperimentResult.Metadata.ExperimentID, ...
        ExpB.ExperimentResult.Metadata.ExperimentID);
    addRow('File', NameA, NameB);
    addRow('Network', ExpA.Environment.InpFileName, ExpB.Environment.InpFileName);
    addRow('Algorithms', ...
        strjoin(ExpA.ExperimentResult.Configuration.Algorithms, '+'), ...
        strjoin(ExpB.ExperimentResult.Configuration.Algorithms, '+'));
    addRow('Runs per algorithm', ...
        ExpA.ExperimentResult.Configuration.NumberOfRuns, ...
        ExpB.ExperimentResult.Configuration.NumberOfRuns);
    addRow('Experiment seed', ...
        ExpA.ExperimentResult.Configuration.ExperimentSeed, ...
        ExpB.ExperimentResult.Configuration.ExperimentSeed);
    addRow('Population / Swarm', ...
        ExpA.ExperimentResult.Configuration.NS, ...
        ExpB.ExperimentResult.Configuration.NS);
    addRow('Max Gen / Iter', ...
        ExpA.ExperimentResult.Configuration.MaxGen, ...
        ExpB.ExperimentResult.Configuration.MaxGen);
    addRow('Min Pressure', ExpA.Problem.Pmin, ExpB.Problem.Pmin);
    addRow('Max Velocity', ExpA.Problem.Vmax, ExpB.Problem.Vmax);
    addRow('Headloss formula', ExpA.Environment.Headloss, ExpB.Environment.Headloss);
    addRow('Fixed Pipes (count)', ...
        numel(ExpA.Problem.FixedPipes), numel(ExpB.Problem.FixedPipes));

    % ---- Per-algorithm statistics (union of algorithms) ----
    AlgsA = ExpA.ExperimentResult.Configuration.Algorithms;
    AlgsB = ExpB.ExperimentResult.Configuration.Algorithms;
    AllAlgs = unique([AlgsA, AlgsB], 'stable');

    for k = 1:numel(AllAlgs)
        Alg = AllAlgs{k};
        addSection(sprintf('%s Statistics', Alg));

        if any(strcmp(AlgsA, Alg))
            SA = ExpA.ExperimentResult.Results.(Alg).Statistics;
        else
            SA = emptyStatistics();
        end

        if any(strcmp(AlgsB, Alg))
            SB = ExpB.ExperimentResult.Results.(Alg).Statistics;
        else
            SB = emptyStatistics();
        end

        addRow('Best Cost', SA.BestCost, SB.BestCost);
        addRow('Mean Cost', SA.MeanCost, SB.MeanCost);
        addRow('Std Cost', SA.StdCost, SB.StdCost);
        addRow('Feasibility %', ...
            100 * SA.FeasibilityRate, 100 * SB.FeasibilityRate);
        addRow('Mean Time (s)', SA.MeanTime, SB.MeanTime);
        addRow('Std Time (s)', SA.StdTime, SB.StdTime);
    end

    % ---------------- nested helpers ----------------

    function addRow(metric, valA, valB)
        Data(end + 1, :) = {metric, formatValue(valA), formatValue(valB), ...
            formatDelta(valA, valB)};
        SectionRows(end + 1, 1) = false;
    end

    function addSection(title)
        Data(end + 1, :) = {['--- ' title ' ---'], '', '', ''};
        SectionRows(end + 1, 1) = true;
    end
end

function s = formatValue(v)
    if ischar(v)
        s = v;
    elseif isstring(v) && isscalar(v)
        s = char(v);
    elseif isnumeric(v) && isscalar(v)
        if isfinite(v)
            s = sprintf('%.4g', v);
        else
            s = '—';
        end
    else
        s = '—';
    end
end

function s = formatDelta(va, vb)
    if isnumeric(va) && isnumeric(vb) && isscalar(va) && isscalar(vb) ...
            && isfinite(va) && isfinite(vb)
        d = vb - va;
        if abs(d) < 1e-10
            s = '0';
        else
            s = sprintf('%+.3g', d);
        end
    else
        s = '';
    end
end

function S = emptyStatistics()
    S.BestCost = NaN;
    S.MeanCost = NaN;
    S.StdCost = NaN;
    S.FeasibilityRate = NaN;
    S.MeanTime = NaN;
    S.StdTime = NaN;
end