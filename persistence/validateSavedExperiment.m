function validateSavedExperiment(Exp)
% Check structure and version of a loaded SavedExperiment struct.

    RequiredTop = {'FormatVersion', 'Environment', 'Settings', 'Config', ...
                   'Problem', 'ExperimentResult', 'Best', 'Hydraulics'};

    for k = 1:numel(RequiredTop)
        if ~isfield(Exp, RequiredTop{k})
            error('WDS:InvalidSavedExperiment', ...
                'Saved experiment is missing field "%s".', RequiredTop{k});
        end
    end

    if Exp.FormatVersion > 1
        error('WDS:UnsupportedFormat', ...
            ['This file was saved with a newer format (v%d). ' ...
             'Update WDS Optimizer to open it.'], Exp.FormatVersion);
    end

    RequiredEnv = {'InpFileContent', 'DFileContent', 'CostFileContent', ...
                   'InpFileName', 'DFileName', 'CostFileName', ...
                   'DUnit', 'Headloss'};

    for k = 1:numel(RequiredEnv)
        if ~isfield(Exp.Environment, RequiredEnv{k})
            error('WDS:InvalidSavedExperiment', ...
                'Environment is missing field "%s".', RequiredEnv{k});
        end
    end

    RequiredBest = {'Algorithm', 'RunIndex', 'Score', 'Position', 'Feasible'};

    for k = 1:numel(RequiredBest)
        if ~isfield(Exp.Best, RequiredBest{k})
            error('WDS:InvalidSavedExperiment', ...
                'Best is missing field "%s".', RequiredBest{k});
        end
    end
end