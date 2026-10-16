function Statistics = aggregateExperimentStatistics(Runs)
%AGGREGATEEXPERIMENTSTATISTICS Aggregate statistics for experiment runs.
%
% Statistics are calculated separately for feasibility/cost and runtime:
%   - Cost statistics use successful feasible runs with finite scores.
%   - Runtime statistics use successful runs with finite nonnegative times.
%   - Feasibility rate uses all recorded runs as its denominator.
%   - Standard deviations use MATLAB's sample standard deviation (N-1).

    if ~isstruct(Runs)
        error('aggregateExperimentStatistics:InvalidRuns', ...
            'Runs must be a struct array.');
    end

    RequiredFields = { ...
        'Status', 'Score', 'Feasible', 'ExecutionTime'};

    for k = 1:numel(RequiredFields)
        if ~isfield(Runs, RequiredFields{k})
            error('aggregateExperimentStatistics:MissingField', ...
                'Runs is missing required field "%s".', ...
                RequiredFields{k});
        end
    end

    TotalRuns = numel(Runs);

    Successful = false(TotalRuns, 1);
    Feasible = false(TotalRuns, 1);
    Scores = nan(TotalRuns, 1);
    Times = nan(TotalRuns, 1);

    for k = 1:TotalRuns
        Status = Runs(k).Status;

        if isstring(Status) && isscalar(Status)
            Status = char(Status);
        end

        if ~ischar(Status)
            error('aggregateExperimentStatistics:InvalidStatus', ...
                'Run %d has an invalid Status value.', k);
        end

        Successful(k) = strcmpi(Status, 'Success');

        if ~islogical(Runs(k).Feasible) || ...
                ~isscalar(Runs(k).Feasible)
            if ~isnumeric(Runs(k).Feasible) || ...
                    ~isscalar(Runs(k).Feasible) || ...
                    ~isfinite(Runs(k).Feasible) || ...
                    ~ismember(Runs(k).Feasible, [0, 1])
                error('aggregateExperimentStatistics:InvalidFeasible', ...
                    'Run %d has an invalid Feasible value.', k);
            end
        end

        Feasible(k) = logical(Runs(k).Feasible);

        if isnumeric(Runs(k).Score) && ...
                isreal(Runs(k).Score) && ...
                isscalar(Runs(k).Score)
            Scores(k) = Runs(k).Score;
        end

        if isnumeric(Runs(k).ExecutionTime) && ...
                isreal(Runs(k).ExecutionTime) && ...
                isscalar(Runs(k).ExecutionTime) && ...
                isfinite(Runs(k).ExecutionTime) && ...
                Runs(k).ExecutionTime >= 0
            Times(k) = Runs(k).ExecutionTime;
        end
    end

    FeasibleSuccessful = Successful & Feasible;
    ValidCosts = FeasibleSuccessful & isfinite(Scores);
    ValidTimes = Successful & isfinite(Times);

    CostValues = Scores(ValidCosts);
    TimeValues = Times(ValidTimes);

    Statistics = struct();

    Statistics.TotalRuns = TotalRuns;
    Statistics.SuccessfulRuns = sum(Successful);

    Failed = false(TotalRuns, 1);
    NotStarted = false(TotalRuns, 1);

    for k = 1:TotalRuns
        Status = Runs(k).Status;

        if isstring(Status) && isscalar(Status)
            Status = char(Status);
        end

        Failed(k) = strcmpi(Status, 'Failed');
        NotStarted(k) = strcmpi(Status, 'NotStarted');
    end

    Statistics.FailedRuns = sum(Failed);
    Statistics.NotStartedRuns = sum(NotStarted);
    Statistics.FeasibleRuns = sum(FeasibleSuccessful);

    if TotalRuns > 0
        Statistics.FeasibilityRate = ...
            Statistics.FeasibleRuns / TotalRuns;
    else
        Statistics.FeasibilityRate = NaN;
    end

    if isempty(CostValues)
        Statistics.BestCost = NaN;
        Statistics.MeanCost = NaN;
        Statistics.StdCost = NaN;
    else
        Statistics.BestCost = min(CostValues);
        Statistics.MeanCost = mean(CostValues);

        if numel(CostValues) > 1
            Statistics.StdCost = std(CostValues);
        else
            Statistics.StdCost = NaN;
        end
    end

    if isempty(TimeValues)
        Statistics.BestTime = NaN;
        Statistics.MeanTime = NaN;
        Statistics.StdTime = NaN;
    else
        Statistics.BestTime = min(TimeValues);
        Statistics.MeanTime = mean(TimeValues);

        if numel(TimeValues) > 1
            Statistics.StdTime = std(TimeValues);
        else
            Statistics.StdTime = NaN;
        end
    end
end