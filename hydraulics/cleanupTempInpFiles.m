function cleanupTempInpFiles(tempInpPath)

    if isempty(tempInpPath)
        return;
    end

    [tempFolder, tempName, ~] = fileparts(tempInpPath);

    filesToDelete = {
        fullfile(tempFolder, [tempName, '.inp'])
        fullfile(tempFolder, [tempName, '.txt'])
        fullfile(tempFolder, [tempName, '_temp.inp'])
        fullfile(tempFolder, [tempName, '_temp.txt'])
        fullfile(tempFolder, [tempName, '_temp.bin'])
    };

    for i = 1:numel(filesToDelete)

        filePath = filesToDelete{i};

        if exist(filePath, 'file') == 2
            try
                delete(filePath);
            catch
                % Ignore cleanup errors.
            end
        end

    end

end