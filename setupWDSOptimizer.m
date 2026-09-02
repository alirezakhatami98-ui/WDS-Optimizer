function setupWDSOptimizer()
%SETUPWDSOPTIMIZER Configure the WDS Optimizer environment.
%
% This function:
%   1. Determines the WDS Optimizer repository root.
%   2. Adds the WDS Optimizer source directories to the MATLAB path.
%   3. Locates the bundled EPANET-MATLAB Toolkit.
%   4. Initializes the official EPANET-MATLAB Toolkit.
%   5. Verifies that the EPANET MATLAB interface is available.
%
% The function does not modify the EPANET-MATLAB Toolkit itself.
%
% Usage:
%   setupWDSOptimizer
%
% The function is intentionally independent of MATLAB's current folder.

    %% 1. Determine project root

    projectRoot = fileparts(mfilename('fullpath'));

    if isempty(projectRoot)
        error( ...
            'WDSOptimizer:Setup:RootNotFound', ...
            'Unable to determine the WDS Optimizer project root.');
    end


    %% 2. Add WDS Optimizer source directories

    sourceFolders = { ...
        'app'
        'algorithms'
        'optimization'
        'hydraulics'
        'data'
        'utils'
    };

    for i = 1:numel(sourceFolders)

        folderPath = fullfile(projectRoot, sourceFolders{i});

        if isfolder(folderPath)
            addpath(genpath(folderPath));
        end

    end


    %% 3. Locate bundled EPANET-MATLAB Toolkit

    toolkitRoot = fullfile( ...
        projectRoot, ...
        'dependencies', ...
        'EPANET-Matlab-Toolkit-2.3.5.2');


    if ~isfolder(toolkitRoot)

        error( ...
            'WDSOptimizer:Setup:ToolkitNotFound', ...
            ['EPANET-MATLAB Toolkit v2.3.5.2 was not found.' newline ...
             'Expected location:' newline ...
             '%s' newline newline ...
             'Please make sure the bundled dependency is present.'], ...
            toolkitRoot);

    end


    %% 4. Verify the official Toolkit entry point

    startToolkitFile = fullfile(toolkitRoot, 'start_toolkit.m');

    if ~isfile(startToolkitFile)

        error( ...
            'WDSOptimizer:Setup:ToolkitInvalid', ...
            ['The EPANET-MATLAB Toolkit was found, but ' ...
             'start_toolkit.m is missing.' newline ...
             'Toolkit location:' newline ...
             '%s'], ...
            toolkitRoot);

    end


    %% 5. Initialize the official EPANET-MATLAB Toolkit

    originalFolder = pwd;

    cleanupObj = onCleanup(@() cd(originalFolder)); 

    cd(toolkitRoot);

    start_toolkit();


    %% 6. Verify EPANET MATLAB interface

    epanetFile = which('epanet');

    if isempty(epanetFile)

        error( ...
            'WDSOptimizer:Setup:EPANETUnavailable', ...
            ['EPANET-MATLAB Toolkit initialization completed, ' ...
             'but the ''epanet'' class could not be found.']);

    end


    %% 7. Display setup confirmation

    fprintf('\n');
    fprintf('WDS Optimizer environment configured successfully.\n');
    fprintf('Project root:\n%s\n', projectRoot);
    fprintf('EPANET-MATLAB Toolkit:\n%s\n', toolkitRoot);
    fprintf('EPANET interface:\n%s\n', epanetFile);
    fprintf('\n');

end