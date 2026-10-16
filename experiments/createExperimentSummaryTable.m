function SummaryTable = createExperimentSummaryTable(ExperimentResult)
%CREATEEXPERIMENTSUMMARYTABLE One row per algorithm with run statistics.
%
% Cost statistics (Best/Mean/Std) use feasible successful runs only,
% exactly as computed by aggregateExperimentStatistics.

    Algorithms = ExperimentResult.Configuration.Algorithms;
    n = numel(Algorithms);

    Algorithm = cell(n, 1);
    Runs = zeros(n, 1);
    Successful = zeros(n, 1);
    Feasible = zeros(n, 1);
    FeasibilityRate_pct = nan(n, 1);
    BestCost = nan(n, 1);
    MeanCost = nan(n, 1);
    StdCost = nan(n, 1);
    MeanTime_s = nan(n, 1);
    StdTime_s = nan(n, 1);

    for a = 1:n

        Name = Algorithms{a};
        S = ExperimentResult.Results.(Name).Statistics;

        Algorithm{a} = Name;
        Runs(a) = S.TotalRuns;
        Successful(a) = S.SuccessfulRuns;
        Feasible(a) = S.FeasibleRuns;
        FeasibilityRate_pct(a) = round(100 * S.FeasibilityRate, 1);
        BestCost(a) = round(S.BestCost, 2);
        MeanCost(a) = round(S.MeanCost, 2);
        StdCost(a) = round(S.StdCost, 2);
        MeanTime_s(a) = round(S.MeanTime, 2);
        StdTime_s(a) = round(S.StdTime, 2);

    end

    SummaryTable = table( ...
        Algorithm, Runs, Successful, Feasible, ...
        FeasibilityRate_pct, BestCost, MeanCost, StdCost, ...
        MeanTime_s, StdTime_s);

end
