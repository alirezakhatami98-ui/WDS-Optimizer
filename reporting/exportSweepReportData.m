function exportSweepReportData(SweepResult, BaseExp, dataDir)
%EXPORTSWEEPREPORTDATA Save sweep data as CSV/XLSX for the report.

    if ~isfolder(dataDir), mkdir(dataDir); end

    Points = SweepResult.Points;
    N = numel(Points);

    % ---- Summary table ----
    T = createSweepSummaryTable(SweepResult);
    writetable(T, fullfile(dataDir, 'sweep_summary.csv'));
    writetable(T, fullfile(dataDir, 'sweep_summary.xlsx'));

    % ---- Points index ----
    Value         = nan(N, 1);
    Status        = cell(N, 1);
    BestScore     = nan(N, 1);
    Feasible      = cell(N, 1);
    WdsxFile      = cell(N, 1);
    WdsxSizeBytes = nan(N, 1);

    for k = 1:N
        P = Points(k);
        Value(k)  = P.Value;
        Status{k} = P.Status;

        if strcmp(P.Status, 'Success')
            BestScore(k) = P.BestScore;
            if P.BestFeasible
                Feasible{k} = 'Yes';
            else
                Feasible{k} = 'No';
            end

            if ~isempty(P.WdsxPath) && isfile(P.WdsxPath)
                [~, name, ext] = fileparts(P.WdsxPath);
                WdsxFile{k} = [name ext];
                info = dir(P.WdsxPath);
                if ~isempty(info)
                    WdsxSizeBytes(k) = info.bytes;
                end
            else
                WdsxFile{k} = '-';
            end
        else
            Feasible{k} = '-';
            WdsxFile{k} = '-';
        end
    end

    writetable(table(Value, Status, BestScore, Feasible, ...
        WdsxFile, WdsxSizeBytes), ...
        fullfile(dataDir, 'points_index.csv'));

    % ---- Per-point convergence ----
    ParamValue = [];
    Generation = [];
    MeanCost   = [];
    MinCost    = [];
    MaxCost    = [];

    SweptAlg = sweptAlgorithmName(SweepResult.Parameter);

    for k = 1:N
        P = Points(k);
        if ~strcmp(P.Status, 'Success'), continue; end
        if isempty(P.WdsxPath) || ~isfile(P.WdsxPath), continue; end
        try
            S = load(P.WdsxPath, '-mat');
            if ~isfield(S, 'SavedExperiment'), continue; end
            E = S.SavedExperiment;
            if isempty(SweptAlg)
                C = E.ExperimentResult.Results.(E.Best.Algorithm).ConvergenceData;
            else
                if ~isfield(E.ExperimentResult.Results, SweptAlg), continue; end
                C = E.ExperimentResult.Results.(SweptAlg).ConvergenceData;
            end
            if isempty(C.Generation), continue; end
            n = numel(C.Generation);
            ParamValue = [ParamValue; repmat(P.Value, n, 1)]; %#ok<AGROW>
            Generation = [Generation; C.Generation]; %#ok<AGROW>
            MeanCost   = [MeanCost; C.Mean]; %#ok<AGROW>
            MinCost    = [MinCost; C.Min]; %#ok<AGROW>
            MaxCost    = [MaxCost; C.Max]; %#ok<AGROW>
        catch
        end
    end

    if ~isempty(Generation)
        writetable(table(ParamValue, Generation, MeanCost, MinCost, MaxCost, ...
            'VariableNames', ...
            {'ParameterValue', 'Generation', 'Mean', 'Min', 'Max'}), ...
            fullfile(dataDir, 'all_points_convergence.csv'));
    end

    % ---- Sweep-level config manifest ----
    manifestPath = fullfile(dataDir, 'sweep_manifest.txt');
    fid = fopen(manifestPath, 'w');
    if fid >= 0
        fprintf(fid, 'WDS Optimizer Sweep Manifest\n');
        fprintf(fid, '============================\n\n');
        fprintf(fid, 'Parameter       : %s\n', SweepResult.Parameter);
        fprintf(fid, 'Values          : %s\n', ...
            strjoin(arrayfun(@(x) sprintf('%g', x), ...
            SweepResult.Values(:)', 'UniformOutput', false), ', '));
        fprintf(fid, 'Sweep status    : %s\n', SweepResult.Status);
        fprintf(fid, 'Output folder   : %s\n\n', SweepResult.OutDir);

        if ~isempty(BaseExp) && isfield(BaseExp, 'ExperimentResult')
            C = BaseExp.ExperimentResult.Configuration;
            fprintf(fid, 'Base algorithms : %s\n', ...
                strjoin(C.Algorithms, ' + '));
            fprintf(fid, 'Runs per alg.   : %d\n', C.NumberOfRuns);
            fprintf(fid, 'Base seed       : %.0f\n', C.ExperimentSeed);
            fprintf(fid, 'Base NS         : %d\n', C.NS);
            fprintf(fid, 'Base MaxGen     : %d\n', C.MaxGen);
        end
        fclose(fid);
    end
end

function alg = sweptAlgorithmName(parameterName)
    if startsWith(parameterName, 'GA_')
        alg = 'GA';
    elseif startsWith(parameterName, 'PSO_')
        alg = 'PSO';
    else
        alg = '';
    end
end