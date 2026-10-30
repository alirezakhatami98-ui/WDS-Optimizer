function exportReportData(Exp, dataDir)
%EXPORTREPORTDATA Save tabular data as CSV/XLSX for the report.

    if ~isfolder(dataDir)
        mkdir(dataDir);
    end

    C   = Exp.ExperimentResult.Configuration;
    Prb = Exp.Problem;

    % ---- Best design (pipes) ----
    pipeTable = createPipeResultsTable( ...
        Prb.NP, Exp.Best.Position, Exp.Hydraulics.PipeVelocities, Prb.Units);
    writetable(pipeTable, fullfile(dataDir, 'best_design.csv'));

    % ---- All runs ----
    RunsTable = createRunsTable(Exp.ExperimentResult);
    writetable(RunsTable, fullfile(dataDir, 'all_runs.csv'));

    % ---- Convergence history ----
    Algorithms = C.Algorithms;
    Gen = []; Mean = []; Min = []; Max = []; Alg = strings(0, 1);

    for a = 1:numel(Algorithms)
        D = Exp.ExperimentResult.Results.(Algorithms{a}).ConvergenceData;
        if isempty(D.Generation), continue; end
        n = numel(D.Generation);
        Gen  = [Gen; D.Generation]; %#ok<AGROW>
        Mean = [Mean; D.Mean]; %#ok<AGROW>
        Min  = [Min; D.Min]; %#ok<AGROW>
        Max  = [Max; D.Max]; %#ok<AGROW>
        Alg  = [Alg; repmat(string(Algorithms{a}), n, 1)]; %#ok<AGROW>
    end

    if ~isempty(Gen)
        writetable(table(Alg, Gen, Mean, Min, Max, ...
            'VariableNames', {'Algorithm', 'Generation', ...
            'Mean', 'Min', 'Max'}), ...
            fullfile(dataDir, 'convergence_raw.csv'));
    end

    % ---- Full Excel (reuses existing exporter) ----
    nodeTable = createNodeResultsTable( ...
        Exp.Hydraulics.NodePressures, Prb.Pmin, Prb.Units);
    SummaryTable = createExperimentSummaryTable(Exp.ExperimentResult);

    exportResultsToExcel(pipeTable, nodeTable, ...
        fullfile(dataDir, 'results.xlsx'), ...
        Exp.ExperimentResult, SummaryTable, RunsTable, Prb.Units);

    % ---- Statistical summary ----
    statPath = fullfile(dataDir, 'statistical_summary.txt');
    fid = fopen(statPath, 'w');
    if fid >= 0
        fprintf(fid, 'WDS Optimizer Statistical Summary\n');
        fprintf(fid, '=================================\n\n');
        fprintf(fid, 'Best cost           : %.4f\n', Exp.Best.Score);

        AlgsAll = C.Algorithms;
        allFeasibleCosts = [];
        TotalRuns = 0;
        FeasRuns = 0;
        for a = 1:numel(AlgsAll)
            Runs = Exp.ExperimentResult.Results.(AlgsAll{a}).Runs;
            TotalRuns = TotalRuns + numel(Runs);
            for r = 1:numel(Runs)
                if strcmp(Runs(r).Status, 'Success') && ...
                        logical(Runs(r).Feasible) && isfinite(Runs(r).Score)
                    FeasRuns = FeasRuns + 1;
                    allFeasibleCosts = [allFeasibleCosts; Runs(r).Score]; %#ok<AGROW>
                end
            end
        end

        if numel(allFeasibleCosts) >= 3
            [ciLo, ciHi] = bootstrapCI(allFeasibleCosts, @mean, 0.05, 2000, 42);
            if isfinite(ciLo)
                fprintf(fid, 'Mean feasible cost  : %.4f (95%% bootstrap CI: [%.4f, %.4f])\n', ...
                    mean(allFeasibleCosts), ciLo, ciHi);
            end
        end

        if TotalRuns > 0
            [wilLo, wilHi] = wilsonCI(FeasRuns, TotalRuns, 0.05);
            fprintf(fid, 'Feasibility rate    : %.1f%% (%d/%d, 95%% Wilson CI: [%.1f%%, %.1f%%])\n', ...
                100 * FeasRuns / TotalRuns, FeasRuns, TotalRuns, ...
                100*wilLo, 100*wilHi);
        end

        fprintf(fid, '\nBootstrap: 2000 resamples, seed 42, percentile method.\n');
        fprintf(fid, 'Wilson: 95%% two-sided score interval.\n');
        fclose(fid);
    end
end