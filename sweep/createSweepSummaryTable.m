function T = createSweepSummaryTable(SweepResult)
%CREATESWEEPSUMMARYTABLE Build a table from a sweep result.

    N = numel(SweepResult.Points);

    Value           = nan(N, 1);
    Status          = cell(N, 1);
    BestCost        = nan(N, 1);
    Feasible        = cell(N, 1);
    Feasibility_pct = nan(N, 1);
    MeanCost        = nan(N, 1);
    StdCost         = nan(N, 1);
    MeanTime_s      = nan(N, 1);
    File            = cell(N, 1);

    for k = 1:N
        P = SweepResult.Points(k);
        Value(k)   = P.Value;
        Status{k}  = P.Status;

        if strcmp(P.Status, 'Success')
            BestCost(k)  = round(P.BestScore, 2);
            MeanCost(k)  = round(P.MeanCost, 2);
            StdCost(k)   = round(P.StdCost, 2);
            MeanTime_s(k)= round(P.MeanTime, 2);
            Feasibility_pct(k) = round(100 * P.FeasibilityRate, 1);

            if P.BestFeasible
                Feasible{k} = 'Yes';
            else
                Feasible{k} = 'No';
            end

            [~, name, ext] = fileparts(P.WdsxPath);
            File{k} = [name ext];
        else
            Feasible{k} = '-';
            File{k}     = '-';
        end
    end

    T = table(Value, Status, BestCost, Feasible, Feasibility_pct, ...
        MeanCost, StdCost, MeanTime_s, File);
end