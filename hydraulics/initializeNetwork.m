function [d, NP, L, InitialD] = initializeNetwork(inpFilePath)

    tempFolder = fileparts(inpFilePath);

    pathEntries = strsplit(path, pathsep);
    isOnPath = any(strcmpi(pathEntries, tempFolder));

    pathAddedHere = false;
    d = [];

    try

        % Add the temporary INP folder only if it is not already on MATLAB path
        if ~isOnPath
            addpath(tempFolder);
            pathAddedHere = true;
        end

        % Create and load the EPANET object
        d = epanet(inpFilePath);

        % Remove the temporary folder from MATLAB path as soon as it is
        % no longer needed for EPANET initialization
        if pathAddedHere
            rmpath(tempFolder);
            pathAddedHere = false;
        end

        % Read network information
        NP = d.getLinkPipeCount();

        L = zeros(NP, 1);
        InitialD = zeros(NP, 1);

        for i = 1:NP
            L(i) = d.getLinkLength(i);
            InitialD(i) = d.getLinkDiameter(i);
        end

    catch ME

        % Restore MATLAB path if this function added the folder
        if pathAddedHere
            try
                rmpath(tempFolder);
            catch
                % Preserve the original error
            end
        end

        % The object has not been handed to the caller yet.
        % Therefore this function is responsible for unloading it.
        if ~isempty(d)
            try
                d.unload();
            catch
                % Preserve the original error
            end
        end

        rethrow(ME);

    end

end