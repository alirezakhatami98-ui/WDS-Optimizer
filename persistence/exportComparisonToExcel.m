function exportComparisonToExcel(ExpA, ExpB, NameA, NameB, fileName)
%EXPORTCOMPARISONTOEXCEL Multi-sheet comparison workbook.

    if isfile(fileName)
        delete(fileName);
    end

    % --- Summary ---
    [Data, ~] = buildComparisonSummaryData(ExpA, ExpB, NameA, NameB);
    T = cell2table(Data, 'VariableNames', ...
        {'Metric', 'ExperimentA', 'ExperimentB', 'Delta_B_minus_A'});
    writetable(T, fileName, 'Sheet', 'Comparison_Summary');

    % --- Per-experiment statistics ---
    writetable(createExperimentSummaryTable(ExpA.ExperimentResult), ...
        fileName, 'Sheet', 'Statistics_A');
    writetable(createExperimentSummaryTable(ExpB.ExperimentResult), ...
        fileName, 'Sheet', 'Statistics_B');

    % --- Convergence per algorithm ---
    AlgsA = ExpA.ExperimentResult.Configuration.Algorithms;
    AlgsB = ExpB.ExperimentResult.Configuration.Algorithms;
    AllAlgs = unique([AlgsA, AlgsB], 'stable');

    for k = 1:numel(AllAlgs)
        Alg = AllAlgs{k};
        hasA = any(strcmp(AlgsA, Alg));
        hasB = any(strcmp(AlgsB, Alg));
        T = buildConvergenceTable(ExpA, ExpB, Alg, hasA, hasB);
        if ~isempty(T)
            writetable(T, fileName, 'Sheet', ['Convergence_' Alg]);
        end
    end

    % --- All runs ---
    writetable(createRunsTable(ExpA.ExperimentResult), ...
        fileName, 'Sheet', 'All_Runs_A');
    writetable(createRunsTable(ExpB.ExperimentResult), ...
        fileName, 'Sheet', 'All_Runs_B');

    % --- Settings ---
    writetable(buildSettingsTable(ExpA, NameA), fileName, 'Sheet', 'Settings_A');
    writetable(buildSettingsTable(ExpB, NameB), fileName, 'Sheet', 'Settings_B');

    % --- Statistical Tests ---
    StatTable = buildStatisticalTestsTable(ExpA, ExpB);
    if ~isempty(StatTable) && height(StatTable) > 0
        writetable(StatTable, fileName, 'Sheet', 'Statistical_Tests');
    end
end

function T = buildConvergenceTable(ExpA, ExpB, Alg, hasA, hasB)

    if hasA
        CA = ExpA.ExperimentResult.Results.(Alg).ConvergenceData;
    else
        CA = emptyConvergence();
    end
    if hasB
        CB = ExpB.ExperimentResult.Results.(Alg).ConvergenceData;
    else
        CB = emptyConvergence();
    end

    n = max(numel(CA.Generation), numel(CB.Generation));

    if n == 0
        T = [];
        return;
    end

    Gen = (1:n)';

    if hasA && hasB
        T = table(Gen, ...
            padTo(CA.Mean, n), padTo(CA.Min, n), padTo(CA.Max, n), ...
            padTo(CB.Mean, n), padTo(CB.Min, n), padTo(CB.Max, n), ...
            'VariableNames', {'Generation', ...
            'A_Mean', 'A_Min', 'A_Max', ...
            'B_Mean', 'B_Min', 'B_Max'});
    elseif hasA
        T = table(Gen, ...
            padTo(CA.Mean, n), padTo(CA.Min, n), padTo(CA.Max, n), ...
            'VariableNames', {'Generation', 'A_Mean', 'A_Min', 'A_Max'});
    else
        T = table(Gen, ...
            padTo(CB.Mean, n), padTo(CB.Min, n), padTo(CB.Max, n), ...
            'VariableNames', {'Generation', 'B_Mean', 'B_Min', 'B_Max'});
    end
end

function padded = padTo(v, n)
    padded = nan(n, 1);
    padded(1:numel(v)) = v(:);
end

function C = emptyConvergence()
    C.Generation = zeros(0, 1);
    C.Mean = zeros(0, 1);
    C.Min  = zeros(0, 1);
    C.Max  = zeros(0, 1);
end

function T = buildStatisticalTestsTable(ExpA, ExpB)
    AlgsA = ExpA.ExperimentResult.Configuration.Algorithms;
    AlgsB = ExpB.ExperimentResult.Configuration.Algorithms;
    CommonAlgs = AlgsA(ismember(AlgsA, AlgsB));

    if isempty(CommonAlgs)
        T = table();
        return;
    end

    n = numel(CommonAlgs);
    Algorithm       = cell(n, 1);
    N_A             = zeros(n, 1);
    N_B             = zeros(n, 1);
    MedianA         = nan(n, 1);
    MedianB         = nan(n, 1);
    PValue          = nan(n, 1);
    Significant     = cell(n, 1);
    CohensD         = nan(n, 1);
    EffectSize      = cell(n, 1);
    DeltaCI_Low     = nan(n, 1);
    DeltaCI_High    = nan(n, 1);

    for k = 1:n
        Alg = CommonAlgs{k};
        S = computeAlgorithmComparisonStats( ...
            ExpA.ExperimentResult.Results.(Alg).Runs, ...
            ExpB.ExperimentResult.Results.(Alg).Runs);

        Algorithm{k}    = Alg;
        N_A(k)          = S.N_A;
        N_B(k)          = S.N_B;
        MedianA(k)      = S.Median_A;
        MedianB(k)      = S.Median_B;
        PValue(k)       = S.PValue;
        CohensD(k)      = S.CohensD;
        EffectSize{k}   = S.EffectSize;
        DeltaCI_Low(k)  = S.DeltaMedianCI_Low;
        DeltaCI_High(k) = S.DeltaMedianCI_High;

        if ~isfinite(S.PValue)
            Significant{k} = 'Insufficient';
        elseif S.Significant
            Significant{k} = 'Yes';
        else
            Significant{k} = 'No';
        end
    end

    T = table(Algorithm, N_A, N_B, MedianA, MedianB, ...
        PValue, Significant, CohensD, EffectSize, ...
        DeltaCI_Low, DeltaCI_High);
end

function T = buildSettingsTable(Exp, Name)

    C   = Exp.ExperimentResult.Configuration;
    Env = Exp.Environment;
    Prb = Exp.Problem;

    Parameter = {
        'File name'
        'Experiment ID'
        'Saved at'
        'Algorithms'
        'Runs per algorithm'
        'Experiment seed'
        'Cache mode'
        'Population / Swarm'
        'Max Gen / Iter'
        'Min Pressure (Pmin)'
        'Max Velocity (Vmax)'
        'Headloss formula'
        'Network (INP)'
        'Diameter file (D.txt)'
        'Cost file'
        'Fixed pipes (count)'
        };

    Value = {
        Name
        Exp.ExperimentResult.Metadata.ExperimentID
        char(Exp.Timestamp)
        strjoin(C.Algorithms, ' + ')
        num2str(C.NumberOfRuns)
        sprintf('%.0f', C.ExperimentSeed)
        C.CacheMode
        num2str(C.NS)
        num2str(C.MaxGen)
        num2str(Prb.Pmin)
        num2str(Prb.Vmax)
        Env.Headloss
        Env.InpFileName
        Env.DFileName
        Env.CostFileName
        num2str(numel(Prb.FixedPipes))
        };

    T = table(Parameter, Value);
end