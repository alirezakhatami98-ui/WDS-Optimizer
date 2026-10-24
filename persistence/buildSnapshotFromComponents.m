function Exp = buildSnapshotFromComponents( ...
    InpFileStr, DFileStr, CostFileStr, ...
    DUnit, Headloss, ...
    Settings, Config, Problem, ...
    ExperimentResult, BestAlgorithm, BestRunIndex, ...
    NodePressures, PipeVelocities, HydraulicsConverged)
%BUILDSNAPSHOTFROMCOMPONENTS Build a saveable struct from explicit parts.
%
% This function has no dependency on the app object, so it can be used
% by the sweep orchestrator and the Save Experiment method alike.

    Exp = struct();
    Exp.FormatVersion = 1;
    Exp.AppVersion    = '1.7.0';
    Exp.Timestamp     = datetime('now');

    % ---- Environment ----
    inpContent  = readFileContent(InpFileStr);
    dContent    = readFileContent(DFileStr);
    costContent = readFileContent(CostFileStr);

    [~, inpBase,  inpExt]  = fileparts(InpFileStr);
    [~, dBase,    dExt]    = fileparts(DFileStr);
    [~, costBase, costExt] = fileparts(CostFileStr);

    Exp.Environment.InpFileName     = [inpBase  inpExt];
    Exp.Environment.InpFilePath     = InpFileStr;
    Exp.Environment.InpFileContent  = inpContent;
    Exp.Environment.InpFileHash     = computeStringHash(inpContent);

    Exp.Environment.DFileName       = [dBase dExt];
    Exp.Environment.DFilePath       = DFileStr;
    Exp.Environment.DFileContent    = dContent;
    Exp.Environment.DFileHash       = computeStringHash(dContent);

    Exp.Environment.CostFileName    = [costBase costExt];
    Exp.Environment.CostFilePath    = CostFileStr;
    Exp.Environment.CostFileContent = costContent;
    Exp.Environment.CostFileHash    = computeStringHash(costContent);

    Exp.Environment.DUnit    = DUnit;
    Exp.Environment.Headloss = Headloss;

    % ---- Settings + Config ----
    Exp.Settings = Settings;
    Exp.Config   = sanitizeConfigForSave(Config);

    % ---- Problem ----
    Exp.Problem = Problem;

    % ---- ExperimentResult ----
    Exp.ExperimentResult = ExperimentResult;

    % ---- Best ----
    BestRun = ExperimentResult.Results.(BestAlgorithm).Runs(BestRunIndex);

    Exp.Best.Algorithm = BestAlgorithm;
    Exp.Best.RunIndex  = BestRunIndex;
    Exp.Best.Score     = BestRun.Score;
    Exp.Best.Position  = BestRun.Position;
    Exp.Best.Feasible  = BestRun.Feasible;

    % ---- Hydraulics ----
    Exp.Hydraulics.NodePressures  = NodePressures;
    Exp.Hydraulics.PipeVelocities = PipeVelocities;
    Exp.Hydraulics.Converged      = HydraulicsConverged;
end