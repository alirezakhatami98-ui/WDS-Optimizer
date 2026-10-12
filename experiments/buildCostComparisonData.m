function CostData = buildCostComparisonData(ExperimentResult)
%BUILDCOSTCOMPARISONDATA Prepare algorithm cost-comparison data.
%
% CostData = buildCostComparisonData(ExperimentResult)
%
% Returns a table with one row per algorithm present in the experiment.
% Cost statistics are taken from the existing Statistics structures.
%
% Output columns:
%   Algorithm, BestCost, MeanCost, StdCost, FeasibleRuns

    if ~isstruct(ExperimentResult) || ...
            ~isscalar(ExperimentResult) || ...
            ~isfield(ExperimentResult, 'Results') || ...
            ~isstruct(ExperimentResult.Results) || ...
            ~isscalar(ExperimentResult.Results)

        error('buildCostComparisonData:InvalidExperimentResult', ...
            'ExperimentResult must contain a scalar Results struct.');
    end

    AlgorithmNames = {'GA', 'PSO'};

    NumberOfAlgorithms = 0;

    for k = 1:numel(AlgorithmNames)
        if isfield(ExperimentResult.Results, AlgorithmNames{k})
            NumberOfAlgorithms = NumberOfAlgorithms + 1;
        end
    end

    Algorithm = cell(NumberOfAlgorithms, 1);
    BestCost = nan(NumberOfAlgorithms, 1);
    MeanCost = nan(NumberOfAlgorithms, 1);
    StdCost = nan(NumberOfAlgorithms, 1);
    FeasibleRuns = zeros(NumberOfAlgorithms, 1);

    Row = 0;

    for k = 1:numel(AlgorithmNames)
        Name = AlgorithmNames{k};

        if ~isfield(ExperimentResult.Results, Name)
            continue;
        end

        AlgorithmResult = ExperimentResult.Results.(Name);

        if ~isstruct(AlgorithmResult) || ...
                ~isscalar(AlgorithmResult) || ...
                ~isfield(AlgorithmResult, 'Statistics') || ...
                ~isstruct(AlgorithmResult.Statistics) || ...
                ~isscalar(AlgorithmResult.Statistics)

            error('buildCostComparisonData:MissingStatistics', ...
                'Algorithm "%s" must contain a scalar Statistics struct.', ...
                Name);
        end

        Statistics = AlgorithmResult.Statistics;

        RequiredFields = { ...
            'BestCost', 'MeanCost', 'StdCost', 'FeasibleRuns'};

        for j = 1:numel(RequiredFields)
            if ~isfield(Statistics, RequiredFields{j})
                error('buildCostComparisonData:MissingStatisticsField', ...
                    'Statistics for "%s" is missing field "%s".', ...
                    Name, RequiredFields{j});
            end
        end

        CostFields = {'BestCost', 'MeanCost', 'StdCost'};

        for j = 1:numel(CostFields)
            Value = Statistics.(CostFields{j});

            if ~isnumeric(Value) || ~isreal(Value) || ~isscalar(Value)
                error('buildCostComparisonData:InvalidCostStatistic', ...
                    'Statistics field "%s" for "%s" must be a real numeric scalar.', ...
                    CostFields{j}, Name);
            end
        end

        FeasibleCount = Statistics.FeasibleRuns;

        if ~isnumeric(FeasibleCount) || ...
                ~isreal(FeasibleCount) || ...
                ~isscalar(FeasibleCount) || ...
                ~isfinite(FeasibleCount) || ...
                FeasibleCount < 0 || ...
                FeasibleCount ~= floor(FeasibleCount)

            error('buildCostComparisonData:InvalidFeasibleRuns', ...
                'FeasibleRuns for "%s" must be a nonnegative integer.', ...
                Name);
        end

        Row = Row + 1;

        Algorithm{Row} = Name;
        BestCost(Row) = Statistics.BestCost;
        MeanCost(Row) = Statistics.MeanCost;
        StdCost(Row) = Statistics.StdCost;
        FeasibleRuns(Row) = FeasibleCount;
    end

    CostData = table( ...
        Algorithm, BestCost, MeanCost, StdCost, FeasibleRuns);
end