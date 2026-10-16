function RunsTable = createRunsTable(ExperimentResult, BestAlgorithm, BestRunIndex)
%CREATERUNSTABLE One row per run of every algorithm in the experiment.

    Algorithms = ExperimentResult.Configuration.Algorithms;

    Total = 0;
    for a = 1:numel(Algorithms)
        Total = Total + ...
            numel(ExperimentResult.Results.(Algorithms{a}).Runs);
    end

    Algorithm = cell(Total, 1);
    Run = zeros(Total, 1);
    Seed = cell(Total, 1);
    Cost = nan(Total, 1);
    Feasible = cell(Total, 1);
    Time_s = nan(Total, 1);
    Status = cell(Total, 1);
    Best = repmat({''}, Total, 1);
    Message = repmat({''}, Total, 1);

    row = 0;

    for a = 1:numel(Algorithms)

        Runs = ExperimentResult.Results.(Algorithms{a}).Runs;

        for r = 1:numel(Runs)

            row = row + 1;
            R = Runs(r);

            Algorithm{row} = Algorithms{a};
            Run(row) = R.RunIndex;
            Seed{row} = sprintf('%.0f', R.Seed);
            Status{row} = R.Status;
            Message{row} = R.ErrorMessage;
            Time_s(row) = round(R.ExecutionTime, 2);

            if strcmp(R.Status, 'Success') && ...
                    isnumeric(R.Score) && isscalar(R.Score)

                Cost(row) = round(R.Score, 2);

                if R.Feasible
                    Feasible{row} = 'Yes';
                else
                    Feasible{row} = 'No';
                end

            else
                Feasible{row} = '-';
            end

            if strcmp(Algorithms{a}, BestAlgorithm) && r == BestRunIndex
                Best{row} = 'Best';
            end

        end
    end

    RunsTable = table( ...
        Algorithm, Run, Seed, Cost, Feasible, Time_s, ...
        Status, Best, Message);

end
