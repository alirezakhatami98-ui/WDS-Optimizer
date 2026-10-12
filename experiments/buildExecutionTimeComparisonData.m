function TimeData = buildExecutionTimeComparisonData(ExperimentResult)
%BUILDEXECUTIONTIMECOMPARISONDATA Prepare runtime comparison data.
%
% TimeData = buildExecutionTimeComparisonData(ExperimentResult)
%
% Output columns:
%   Algorithm, MeanTime, StdTime, SuccessfulRuns

    if ~isstruct(ExperimentResult) || ...
            ~isscalar(ExperimentResult) || ...
            ~isfield(ExperimentResult, 'Results') || ...
            ~isstruct(ExperimentResult.Results) || ...
            ~isscalar(ExperimentResult.Results)

        error('buildExecutionTimeComparisonData:InvalidExperimentResult', ...
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
    MeanTime = nan(NumberOfAlgorithms, 1);
    StdTime = nan(NumberOfAlgorithms, 1);
    SuccessfulRuns = zeros(NumberOfAlgorithms, 1);

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

            error('buildExecutionTimeComparisonData:MissingStatistics', ...
                'Algorithm "%s" must contain a scalar Statistics struct.', ...
                Name);
        end

        Statistics = AlgorithmResult.Statistics;

        RequiredFields = {'MeanTime', 'StdTime', 'SuccessfulRuns'};

        for j = 1:numel(RequiredFields)
            if ~isfield(Statistics, RequiredFields{j})
                error('buildExecutionTimeComparisonData:MissingStatisticsField', ...
                    'Statistics for "%s" is missing field "%s".', ...
                    Name, RequiredFields{j});
            end
        end

        TimeFields = {'MeanTime', 'StdTime'};

        for j = 1:numel(TimeFields)
            Value = Statistics.(TimeFields{j});

            if ~isnumeric(Value) || ~isreal(Value) || ~isscalar(Value)
                error('buildExecutionTimeComparisonData:InvalidTimeStatistic', ...
                    'Statistics field "%s" for "%s" must be a real numeric scalar.', ...
                    TimeFields{j}, Name);
            end
        end

        SuccessfulCount = Statistics.SuccessfulRuns;

        if ~isnumeric(SuccessfulCount) || ...
                ~isreal(SuccessfulCount) || ...
                ~isscalar(SuccessfulCount) || ...
                ~isfinite(SuccessfulCount) || ...
                SuccessfulCount < 0 || ...
                SuccessfulCount ~= floor(SuccessfulCount)

            error('buildExecutionTimeComparisonData:InvalidSuccessfulRuns', ...
                'SuccessfulRuns for "%s" must be a nonnegative integer.', ...
                Name);
        end

        Row = Row + 1;

        Algorithm{Row} = Name;
        MeanTime(Row) = Statistics.MeanTime;
        StdTime(Row) = Statistics.StdTime;
        SuccessfulRuns(Row) = SuccessfulCount;
    end

    TimeData = table( ...
        Algorithm, MeanTime, StdTime, SuccessfulRuns);
end