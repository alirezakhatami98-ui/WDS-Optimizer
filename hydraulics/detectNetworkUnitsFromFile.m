function Units = detectNetworkUnitsFromFile(inpFile)

    [d, ~, ~, ~] = initializeNetwork(inpFile);
    cleanupObj = onCleanup(@() cleanupEpanetObject(d)); %#ok<NASGU>

    Units = detectNetworkUnits(d);

end