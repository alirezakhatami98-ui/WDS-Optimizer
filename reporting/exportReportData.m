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
end