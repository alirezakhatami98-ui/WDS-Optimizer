function SummaryTable = buildAlgorithmSummaryTable(ExperimentResult)
%BUILDALGORITHMSUMMARYTABLE Build a summary table for experiment algorithms.
%
%   SummaryTable = buildAlgorithmSummaryTable(ExperimentResult)
%
%   Required structure:
%       ExperimentResult.Results.(Algorithm).Statistics
%
%   One row is produced for each algorithm with available statistics.
%
%   Cost statistics include only successful feasible runs with finite
%   scores. Runtime statistics follow aggregateExperimentStatistics.
%
%   The input ExperimentResult is not modified.

    %% Validate input

    if ~isstruct(ExperimentResult) || ...
            ~isscalar(ExperimentResult) || ...
            ~isfield(ExperimentResult, 'Results') || ...
            ~isstruct(ExperimentResult.Results) || ...
            ~isscalar(ExperimentResult.Results)

        error('buildAlgorithmSummaryTable:InvalidExperimentResult', ...
            'ExperimentResult must contain a scalar Results structure.');
    end

    Results = ExperimentResult.Results;

    %% Collect rows for available algorithms

    AlgorithmNames = {'GA', 'PSO'};
    MaxAlgorithms = numel(AlgorithmNames);

    Algorithm = cell(MaxAlgorithms, 1);
    TotalRuns = zeros(MaxAlgorithms, 1);
    SuccessfulRuns = zeros(MaxAlgorithms, 1);
    FailedRuns = zeros(MaxAlgorithms, 1);
    FeasibleRuns = zeros(MaxAlgorithms, 1);
    FeasibilityRate = zeros(MaxAlgorithms, 1);
    BestCost = zeros(MaxAlgorithms, 1);
    MeanCost = zeros(MaxAlgorithms, 1);
    StdCost = zeros(MaxAlgorithms, 1);
    BestTime = zeros(MaxAlgorithms, 1);
    MeanTime = zeros(MaxAlgorithms, 1);
    StdTime = zeros(MaxAlgorithms, 1);

    RequiredStatistics = { ...
        'TotalRuns', ...
        'SuccessfulRuns', ...
        'FailedRuns', ...
        'FeasibleRuns', ...
        'FeasibilityRate', ...
        'BestCost', ...
        'MeanCost', ...
        'StdCost', ...
        'BestTime', ...
        'MeanTime', ...
        'StdTime'};

    NumberOfAlgorithms = 0;

    for k = 1:numel(AlgorithmNames)

        Name = AlgorithmNames{k};

        if ~isfield(Results, Name)
            continue;
        end

        if ~isfield(Results.(Name), 'Statistics')
            error('buildAlgorithmSummaryTable:MissingStatistics', ...
                'Results.%s is missing Statistics.', Name);
        end

        Statistics = Results.(Name).Statistics;

        if ~isstruct(Statistics) || ~isscalar(Statistics)
            error('buildAlgorithmSummaryTable:InvalidStatistics', ...
                'Statistics for %s must be a scalar structure.', Name);
        end

        for j = 1:numel(RequiredStatistics)
            if ~isfield(Statistics, RequiredStatistics{j})
                error('buildAlgorithmSummaryTable:MissingStatisticField', ...
                    'Statistics for %s is missing field "%s".', ...
                    Name, RequiredStatistics{j});
            end
        end

        NumberOfAlgorithms = NumberOfAlgorithms + 1;

        Algorithm{NumberOfAlgorithms} = Name;

        TotalRuns(NumberOfAlgorithms) = Statistics.TotalRuns;
        SuccessfulRuns(NumberOfAlgorithms) = Statistics.SuccessfulRuns;
        FailedRuns(NumberOfAlgorithms) = Statistics.FailedRuns;
        FeasibleRuns(NumberOfAlgorithms) = Statistics.FeasibleRuns;
        FeasibilityRate(NumberOfAlgorithms) = Statistics.FeasibilityRate;
        BestCost(NumberOfAlgorithms) = Statistics.BestCost;
        MeanCost(NumberOfAlgorithms) = Statistics.MeanCost;
        StdCost(NumberOfAlgorithms) = Statistics.StdCost;
        BestTime(NumberOfAlgorithms) = Statistics.BestTime;
        MeanTime(NumberOfAlgorithms) = Statistics.MeanTime;
        StdTime(NumberOfAlgorithms) = Statistics.StdTime;

    end

    %% Remove unused preallocated rows

    Algorithm = Algorithm(1:NumberOfAlgorithms);
    TotalRuns = TotalRuns(1:NumberOfAlgorithms);
    SuccessfulRuns = SuccessfulRuns(1:NumberOfAlgorithms);
    FailedRuns = FailedRuns(1:NumberOfAlgorithms);
    FeasibleRuns = FeasibleRuns(1:NumberOfAlgorithms);
    FeasibilityRate = FeasibilityRate(1:NumberOfAlgorithms);
    BestCost = BestCost(1:NumberOfAlgorithms);
    MeanCost = MeanCost(1:NumberOfAlgorithms);
    StdCost = StdCost(1:NumberOfAlgorithms);
    BestTime = BestTime(1:NumberOfAlgorithms);
    MeanTime = MeanTime(1:NumberOfAlgorithms);
    StdTime = StdTime(1:NumberOfAlgorithms);



    %% Build output table

    SummaryTable = table( ...
        Algorithm, ...
        TotalRuns, ...
        SuccessfulRuns, ...
        FailedRuns, ...
        FeasibleRuns, ...
        FeasibilityRate, ...
        BestCost, ...
        MeanCost, ...
        StdCost, ...
        BestTime, ...
        MeanTime, ...
        StdTime);

end