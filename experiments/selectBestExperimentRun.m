function [BestAlgorithm, BestRunIndex, BestRun] = ...
    selectBestExperimentRun(ExpResult)
%SELECTBESTEXPERIMENTRUN Choose the best candidate from an experiment.
%
% Prefers feasible runs (lowest cost) over infeasible runs.

    Algorithms = ExpResult.Configuration.Algorithms;

    Total = 0;
    for a = 1:numel(Algorithms)
        Total = Total + numel(ExpResult.Results.(Algorithms{a}).Runs);
    end

    Scores       = nan(Total, 1);
    Feasible     = false(Total, 1);
    Algs         = cell(Total, 1);
    RunIndices   = zeros(Total, 1);
    Count = 0;

    for a = 1:numel(Algorithms)
        Alg  = Algorithms{a};
        Runs = ExpResult.Results.(Alg).Runs;

        for r = 1:numel(Runs)
            if ~strcmp(Runs(r).Status, 'Success'), continue; end
            if ~isnumeric(Runs(r).Score) || ~isscalar(Runs(r).Score) || ...
                    ~isfinite(Runs(r).Score)
                continue;
            end
            Count = Count + 1;
            Scores(Count)     = Runs(r).Score;
            Feasible(Count)   = logical(Runs(r).Feasible);
            Algs{Count}       = Alg;
            RunIndices(Count) = r;
        end
    end

    Scores     = Scores(1:Count);
    Feasible   = Feasible(1:Count);
    Algs       = Algs(1:Count);
    RunIndices = RunIndices(1:Count);

    if isempty(Scores)
        error('selectBestExperimentRun:NoCandidates', ...
            'No successful runs are available.');
    end

    FeasIdx = find(Feasible);
    if ~isempty(FeasIdx)
        [~, li] = min(Scores(FeasIdx));
        BestCandidateIndex = FeasIdx(li);
    else
        [~, BestCandidateIndex] = min(Scores);
    end

    BestAlgorithm = Algs{BestCandidateIndex};
    BestRunIndex  = RunIndices(BestCandidateIndex);
    BestRun       = ExpResult.Results.(BestAlgorithm).Runs(BestRunIndex);
end