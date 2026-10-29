function outDir = generateSweepReport(SweepResult, parentDir)
%GENERATESWEEPREPORT Build a complete sweep report bundle.
%
%   outDir = generateSweepReport(SweepResult, parentDir)
%
%   SweepResult : the struct returned by runParameterSweep
%   parentDir   : folder where WDS_SweepReport_<param>_<timestamp>/ is created

    if isempty(SweepResult) || ~isfield(SweepResult, 'Points')
        error('WDS:SweepReport:InvalidInput', ...
            'SweepResult must be a valid sweep result struct.');
    end

    BaseExp = loadFirstSuccessfulExperiment(SweepResult);
    if isempty(BaseExp) || ~isfield(BaseExp, 'Environment')
        error('WDS:SweepReport:NoSuccessfulPoints', ...
            ['Cannot generate a sweep report: no successful sweep ' ...
             'points with saved .wdsx files exist.']);
    end

    ParamTag = regexprep(SweepResult.Parameter, '[^A-Za-z0-9]', '');
    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    outDir = fullfile(parentDir, ...
        sprintf('WDS_SweepReport_%s_%s', ParamTag, stamp));
    mkdir(outDir);

    bundleReportInputs(BaseExp, outDir);
    exportSweepReportFigures(SweepResult, fullfile(outDir, 'figures'), BaseExp);
    exportSweepReportData(SweepResult, BaseExp, fullfile(outDir, 'data'));

    md = buildSweepReportMarkdown(SweepResult, BaseExp);
    reportPath = fullfile(outDir, 'SWEEP_REPORT.md');

    fid = fopen(reportPath, 'w', 'n', 'UTF-8');
    if fid < 0
        error('WDS:SweepReport:WriteError', ...
            'Cannot open report file for writing: %s', reportPath);
    end
    cleaner = onCleanup(@() fclose(fid)); 

    for k = 1:numel(md)
        fprintf(fid, '%s\n', md(k));
    end
end

function BaseExp = loadFirstSuccessfulExperiment(SweepResult)
    BaseExp = [];
    for k = 1:numel(SweepResult.Points)
        P = SweepResult.Points(k);
        if ~strcmp(P.Status, 'Success'), continue; end
        if isempty(P.WdsxPath) || ~isfile(P.WdsxPath), continue; end
        try
            S = load(P.WdsxPath, '-mat');
            if isfield(S, 'SavedExperiment')
                BaseExp = S.SavedExperiment;
                return;
            end
        catch
        end
    end
end