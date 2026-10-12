function DetailsTable = buildRunDetailsTable(ExperimentResult)
%BUILDRUNDETAILSTABLE Build a row-per-run experiment details table.
%
%   DetailsTable = buildRunDetailsTable(ExperimentResult)
%
%   One row is produced for each recorded run. Algorithms are ordered
%   GA then PSO, and runs retain their order within each algorithm.
%
%   The input ExperimentResult is not modified.

    %% Validate input

    if ~isstruct(ExperimentResult) || ...
            ~isscalar(ExperimentResult) || ...
            ~isfield(ExperimentResult, 'Results') || ...
            ~isstruct(ExperimentResult.Results) || ...
            ~isscalar(ExperimentResult.Results)

        error('buildRunDetailsTable:InvalidExperimentResult', ...
            'ExperimentResult must contain a scalar Results structure.');
    end

    Results = ExperimentResult.Results;

    %% Preallocate for the maximum number of rows

    AlgorithmNames = {'GA', 'PSO'};
    MaxRuns = 0;

    for k = 1:numel(AlgorithmNames)
        Name = AlgorithmNames{k};

        if isfield(Results, Name) && ...
                isfield(Results.(Name), 'Runs')

            Runs = Results.(Name).Runs;

            if ~isstruct(Runs)
                error('buildRunDetailsTable:InvalidRuns', ...
                    'Results.%s.Runs must be a struct array.', Name);
            end

            MaxRuns = MaxRuns + numel(Runs);
        end
    end

    Algorithm = cell(MaxRuns, 1);
    RunIndex = zeros(MaxRuns, 1);
    Seed = zeros(MaxRuns, 1);
    Status = cell(MaxRuns, 1);
    Feasible = false(MaxRuns, 1);
    Score = nan(MaxRuns, 1);
    ExecutionTime = nan(MaxRuns, 1);

    RequiredFields = { ...
        'Algorithm', ...
        'RunIndex', ...
        'Seed', ...
        'Status', ...
        'Feasible', ...
        'Score', ...
        'ExecutionTime'};

    %% Collect run records

    Row = 0;

    for k = 1:numel(AlgorithmNames)

        Name = AlgorithmNames{k};

        if ~isfield(Results, Name) || ...
                ~isfield(Results.(Name), 'Runs')
            continue;
        end

        Runs = Results.(Name).Runs;

        for r = 1:numel(Runs)

            for j = 1:numel(RequiredFields)
                if ~isfield(Runs, RequiredFields{j})
                    error('buildRunDetailsTable:MissingRunField', ...
                        'A run in Results.%s.Runs is missing field "%s".', ...
                        Name, RequiredFields{j});
                end
            end

            Row = Row + 1;

            Algorithm{Row} = Name;
            RunIndex(Row) = Runs(r).RunIndex;
            Seed(Row) = Runs(r).Seed;

            RunStatus = Runs(r).Status;
            if isstring(RunStatus) && isscalar(RunStatus)
                RunStatus = char(RunStatus);
            end

            if ~ischar(RunStatus)
                error('buildRunDetailsTable:InvalidStatus', ...
                    'Run %d for %s has an invalid Status.', r, Name);
            end
            Status{Row} = RunStatus;

            RunFeasible = Runs(r).Feasible;
            if islogical(RunFeasible) && isscalar(RunFeasible)
                Feasible(Row) = RunFeasible;
            elseif isnumeric(RunFeasible) && ...
                    isreal(RunFeasible) && ...
                    isscalar(RunFeasible) && ...
                    isfinite(RunFeasible) && ...
                    ismember(RunFeasible, [0, 1])
                Feasible(Row) = logical(RunFeasible);
            else
                error('buildRunDetailsTable:InvalidFeasible', ...
                    'Run %d for %s has an invalid Feasible value.', ...
                    r, Name);
            end

            RunScore = Runs(r).Score;
            if isnumeric(RunScore) && ...
                    isreal(RunScore) && isscalar(RunScore)
                Score(Row) = RunScore;
            else
                error('buildRunDetailsTable:InvalidScore', ...
                    'Run %d for %s has an invalid Score.', r, Name);
            end

            RunTime = Runs(r).ExecutionTime;
            if isnumeric(RunTime) && ...
                    isreal(RunTime) && isscalar(RunTime)
                ExecutionTime(Row) = RunTime;
            else
                error('buildRunDetailsTable:InvalidExecutionTime', ...
                    'Run %d for %s has an invalid ExecutionTime.', ...
                    r, Name);
            end

        end
    end

    %% Build output table

    DetailsTable = table( ...
        Algorithm, ...
        RunIndex, ...
        Seed, ...
        Status, ...
        Feasible, ...
        Score, ...
        ExecutionTime);

end