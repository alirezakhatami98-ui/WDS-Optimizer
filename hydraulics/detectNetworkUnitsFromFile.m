function Units = detectNetworkUnitsFromFile(inpFile)

    tempInpPath = createTempInpFile(inpFile);

    d = [];

    try
        [d, ~, ~, ~] = initializeNetwork(tempInpPath);

        Units = detectNetworkUnits(d);

    catch ME
        if ~isempty(d)
            cleanupEpanetObject(d);
        end

        cleanupTempInpFiles(tempInpPath);
        rethrow(ME);
    end

    cleanupEpanetObject(d);
    cleanupTempInpFiles(tempInpPath);

end