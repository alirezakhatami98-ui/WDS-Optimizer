function bundleReportInputs(Exp, outDir)
%BUNDLEREPORTINPUTS Write input files and SHA-256 manifest into the report.

    inputDir = fullfile(outDir, 'inputs');
    if ~isfolder(inputDir)
        mkdir(inputDir);
    end

    writeFileContent(fullfile(inputDir, Exp.Environment.InpFileName), ...
        Exp.Environment.InpFileContent);
    writeFileContent(fullfile(inputDir, Exp.Environment.DFileName), ...
        Exp.Environment.DFileContent);
    writeFileContent(fullfile(inputDir, Exp.Environment.CostFileName), ...
        Exp.Environment.CostFileContent);

    manifest = fullfile(inputDir, 'manifest.txt');
    fid = fopen(manifest, 'w');
    if fid < 0
        warning('WDS:Report:Manifest', ...
            'Cannot write manifest: %s', manifest);
        return;
    end

    fprintf(fid, 'WDS Optimizer Input Manifest\n');
    fprintf(fid, '===========================\n\n');
    fprintf(fid, 'Network (INP):  %s\n', Exp.Environment.InpFileName);
    fprintf(fid, '  SHA-256     : %s\n\n', Exp.Environment.InpFileHash);
    fprintf(fid, 'Diameter file:  %s\n', Exp.Environment.DFileName);
    fprintf(fid, '  SHA-256     : %s\n\n', Exp.Environment.DFileHash);
    fprintf(fid, 'Cost file:      %s\n', Exp.Environment.CostFileName);
    fprintf(fid, '  SHA-256     : %s\n\n', Exp.Environment.CostFileHash);
    fprintf(fid, 'D.txt unit:     %s\n', Exp.Environment.DUnit);
    fprintf(fid, 'Headloss:       %s\n', Exp.Environment.Headloss);
    fclose(fid);
end