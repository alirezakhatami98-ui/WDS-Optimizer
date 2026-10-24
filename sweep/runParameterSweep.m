function SweepResult = runParameterSweep( ...
    d, Problem, BaseConfig, BaseOptions, ...
    ParameterName, ParameterValues, Environment, ...
    ProgressCallback, CancelCallback)
%RUNPARAMETERSWEEP Sweep one algorithm parameter across several values.
%
% Each sweep point is executed by runExperiment and saved as a .wdsx
% snapshot inside Environment.OutDir. Successful points record their
% best score, feasibility statistics and execution time.

    validateSweepConfiguration(BaseOptions, ParameterName, ParameterValues);

    NPoints = numel(ParameterValues);
    OutDir  = Environment.OutDir;

    if ~isfolder(OutDir)
        [ok, msg] = mkdir(OutDir);
        if ~ok
            error('sweep:OutputFolder', ...
                'Cannot create output folder: %s', msg);
        end
    end

    % ---- Initialize result container ----
    SweepResult = struct();
    SweepResult.Parameter = ParameterName;
    SweepResult.Values    = ParameterValues(:);
    SweepResult.OutDir    = OutDir;
    SweepResult.Status    = '';

    PointTemplate = struct( ...
        'Value',            NaN, ...
        'Status',           'NotStarted', ...
        'BestScore',        NaN, ...
        'BestFeasible',     false, ...
        'FeasibilityRate',  NaN, ...
        'MeanCost',         NaN, ...
        'StdCost',          NaN, ...
        'MeanTime',         NaN, ...
        'TotalTime',        NaN, ...
        'WdsxPath',         '', ...
        'ErrorMessage',     '');

    SweepResult.Points = repmat(PointTemplate, NPoints, 1);

    % ---- Iterate over sweep points ----
    for k = 1:NPoints

        if ~isempty(CancelCallback) && CancelCallback()
            SweepResult.Status = 'Cancelled';
            break;
        end

        Value = ParameterValues(k);

        if ~isempty(ProgressCallback)
            ProgressCallback(struct( ...
                'Phase',           'StartingPoint', ...
                'PointIndex',      k, ...
                'TotalPoints',     NPoints, ...
                'ParameterName',   ParameterName, ...
                'ParameterValue',  Value));
        end

        [PointConfig, PointOptions, PointSettings] = ...
            applySweepParameter(BaseConfig, BaseOptions, ...
                Environment.BaseSettings, ParameterName, Value);

        % Attach per-run progress forwarding
        if ~isempty(ProgressCallback)
            PointOptions.ProgressCallback = @(PI) ProgressCallback(struct( ...
                'Phase',           'RunProgress', ...
                'PointIndex',      k, ...
                'TotalPoints',     NPoints, ...
                'ParameterName',   ParameterName, ...
                'ParameterValue',  Value, ...
                'ProgressInfo',    PI));
        end
        if ~isempty(CancelCallback)
            PointOptions.CancelCallback = CancelCallback;
        end

        PointTimer = tic;
        SweepResult.Points(k).Value = Value;

        try
            ExpResult = runExperiment(d, Problem, PointConfig, PointOptions);
            Elapsed   = toc(PointTimer);

            % If cancellation was requested during this point, stop
            % here without saving a partial snapshot. A partial point
            % based on fewer runs than intended would bias the trend.
            if ~isempty(CancelCallback) && CancelCallback()
                SweepResult.Points(k).Status    = 'Cancelled';
                SweepResult.Points(k).TotalTime = Elapsed;
                SweepResult.Status = 'Cancelled';
                break;
            end

            [BestAlgorithm, BestRunIndex, BestRun] = ...
                selectBestExperimentRun(ExpResult);

            [NP_vals, VP_vals, Converged] = ...
                calculateHydraulicResults(d, BestRun.Position, Problem.NP);

            Hydraulics.NodePressures  = NP_vals;
            Hydraulics.PipeVelocities = VP_vals;
            Hydraulics.Converged      = Converged;

            WdsxPath = fullfile(OutDir, ...
                sprintf('point_%g.wdsx', Value));

            Exp = buildSnapshotFromComponents( ...
                Environment.InpFileStr, Environment.DFileStr, ...
                Environment.CostFileStr, ...
                Environment.DUnit, Environment.Headloss, ...
                PointSettings, PointConfig, Problem, ...
                ExpResult, BestAlgorithm, BestRunIndex, ...
                Hydraulics.NodePressures, Hydraulics.PipeVelocities, ...
                Hydraulics.Converged);

            SavedExperiment = Exp; 
            save(WdsxPath, 'SavedExperiment', '-v7.3', '-mat');

            % ---- Aggregate statistics across all algorithms ----
            [BestScore, BestFeasible, FeasRate, MeanCost, StdCost, MeanTime] = ...
                summarizeExperiment(ExpResult, BestRun);

            SweepResult.Points(k).Status          = 'Success';
            SweepResult.Points(k).BestScore       = BestScore;
            SweepResult.Points(k).BestFeasible    = BestFeasible;
            SweepResult.Points(k).FeasibilityRate = FeasRate;
            SweepResult.Points(k).MeanCost        = MeanCost;
            SweepResult.Points(k).StdCost         = StdCost;
            SweepResult.Points(k).MeanTime        = MeanTime;
            SweepResult.Points(k).TotalTime       = Elapsed;
            SweepResult.Points(k).WdsxPath        = WdsxPath;

            if ~isempty(ProgressCallback)
                ProgressCallback(struct( ...
                    'Phase',          'PointDone', ...
                    'PointIndex',     k, ...
                    'TotalPoints',    NPoints, ...
                    'ParameterName',  ParameterName, ...
                    'ParameterValue', Value, ...
                    'BestScore',      BestScore, ...
                    'BestFeasible',   BestFeasible));
            end

        catch ME
            Elapsed = toc(PointTimer);

            if strcmp(ME.identifier, 'WDSOptimizer:ExperimentCancelled')
                SweepResult.Points(k).Status = 'Cancelled';
                SweepResult.Status = 'Cancelled';
                break;
            else
                SweepResult.Points(k).Status       = 'Failed';
                SweepResult.Points(k).TotalTime    = Elapsed;
                SweepResult.Points(k).ErrorMessage = ME.message;

                warning('sweep:PointFailed', ...
                    'Sweep point %d/%d (%s = %g) failed: %s', ...
                    k, NPoints, ParameterName, Value, ME.message);
            end
        end
    end

    if isempty(SweepResult.Status)
        SweepResult.Status = 'Completed';
    end
end

% ---- Local helpers ----
function [BestScore, BestFeasible, FeasRate, MeanCost, StdCost, MeanTime] = ...
    summarizeExperiment(ExpResult, BestRun)

    BestScore    = BestRun.Score;
    BestFeasible = BestRun.Feasible;

    Algs = ExpResult.Configuration.Algorithms;

    TotalRuns = 0;
    FeasRuns  = 0;
    Costs     = [];
    Times     = [];

    for a = 1:numel(Algs)
        Alg  = Algs{a};
        Runs = ExpResult.Results.(Alg).Runs;

        for r = 1:numel(Runs)
            TotalRuns = TotalRuns + 1;
            if ~strcmp(Runs(r).Status, 'Success'), continue; end

            if isfinite(Runs(r).ExecutionTime)
                Times(end + 1) = Runs(r).ExecutionTime; %#ok<AGROW>
            end

            if logical(Runs(r).Feasible) && ...
                    isfinite(Runs(r).Score)
                FeasRuns = FeasRuns + 1;
                Costs(end + 1) = Runs(r).Score; %#ok<AGROW>
            end
        end
    end

    FeasRate = FeasRuns / max(TotalRuns, 1);
    MeanCost = meanOrNaN(Costs);
    StdCost  = stdOrNaN(Costs);
    MeanTime = meanOrNaN(Times);
end

function m = meanOrNaN(v)
    if isempty(v), m = NaN; else, m = mean(v); end
end

function s = stdOrNaN(v)
    if numel(v) > 1, s = std(v); else, s = NaN; end
end