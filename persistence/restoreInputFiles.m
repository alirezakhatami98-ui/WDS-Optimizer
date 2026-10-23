function [inpPath, dPath, costPath] = restoreInputFiles(Env)
% Write stored input contents to fresh temporary files so the
% optimization pipeline can re-run against identical inputs.

    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss_SSS'));
    restoredDir = fullfile(tempdir, sprintf('wdsx_restored_%s', stamp));

    [ok, msg] = mkdir(restoredDir);
    if ~ok
        error('WDS:TempDir', 'Cannot create temporary folder: %s', msg);
    end

    inpPath  = fullfile(restoredDir, Env.InpFileName);
    dPath    = fullfile(restoredDir, Env.DFileName);
    costPath = fullfile(restoredDir, Env.CostFileName);

    writeFileContent(inpPath,  Env.InpFileContent);
    writeFileContent(dPath,    Env.DFileContent);
    writeFileContent(costPath, Env.CostFileContent);
end