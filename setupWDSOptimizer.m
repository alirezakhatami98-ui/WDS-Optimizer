function setupWDSOptimizer()
% setupWDSOptimizer
% Configures the MATLAB path for the WDS Optimization Toolkit.
%
% This function only configures paths for the WDS Optimizer source code.
% EPANET Toolkit initialization is intentionally handled separately.

projectRoot = fileparts(mfilename('fullpath'));

projectFolders = {
    'app'
    'algorithms'
    'optimization'
    'hydraulics'
    'data'
    'results'
};

for i = 1:numel(projectFolders)

    folderPath = fullfile(projectRoot, projectFolders{i});

    if isfolder(folderPath)
        addpath(folderPath);
    else
        error( ...
            'WDSOptimizer:MissingFolder', ...
            'Required project folder not found: %s', ...
            folderPath);
    end

end

fprintf('WDS Optimizer paths configured successfully.\n');

end
