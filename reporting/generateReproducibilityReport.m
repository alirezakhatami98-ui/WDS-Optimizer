function outDir = generateReproducibilityReport(Exp, parentDir)
%GENERATEREPRODUCIBILITYREPORT Build a complete reproducibility bundle.
%
%   outDir = generateReproducibilityReport(Exp, parentDir)
%
%   Exp     : a SavedExperiment struct (from BuildExperimentSnapshot or
%             loaded from a .wdsx file)
%   parentDir : folder where WDS_Report_<timestamp>/ will be created
%
%   Returns the full path to the created report folder.

    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    outDir = fullfile(parentDir, sprintf('WDS_Report_%s', stamp));

    mkdir(outDir);

    bundleReportInputs(Exp, outDir);
    exportReportFigures(Exp, fullfile(outDir, 'figures'));
    exportReportData(Exp, fullfile(outDir, 'data'));

    md = buildReportMarkdown(Exp);
    reportPath = fullfile(outDir, 'REPORT.md');

    fid = fopen(reportPath, 'w', 'n', 'UTF-8');
    if fid < 0
        error('WDS:Report:WriteError', ...
            'Cannot open report file for writing: %s', reportPath);
    end
    cleaner = onCleanup(@() fclose(fid));

    for k = 1:numel(md)
        fprintf(fid, '%s\n', md(k));
    end
end