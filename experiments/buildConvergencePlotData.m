function PlotData = buildConvergencePlotData(ExperimentResult)
%BUILDCONVERGENCEPLOTDATA Prepare convergence data for plotting.
%
% PlotData = buildConvergencePlotData(ExperimentResult)
%
% Returns one field per available algorithm (GA and/or PSO).
% Each field contains the existing ConvergenceData structure:
%   Generation, Mean, Std, Median, Min, Max, NumRuns.
%
% This function does not recalculate convergence statistics.

    if ~isstruct(ExperimentResult) || ...
            ~isscalar(ExperimentResult) || ...
            ~isfield(ExperimentResult, 'Results') || ...
            ~isstruct(ExperimentResult.Results) || ...
            ~isscalar(ExperimentResult.Results)

        error('buildConvergencePlotData:InvalidExperimentResult', ...
            'ExperimentResult must contain a scalar Results struct.');
    end

    AlgorithmNames = {'GA', 'PSO'};
    PlotData = struct();

    RequiredFields = { ...
        'Generation', 'Mean', 'Std', ...
        'Median', 'Min', 'Max', 'NumRuns'};

    for k = 1:numel(AlgorithmNames)
        Name = AlgorithmNames{k};

        if ~isfield(ExperimentResult.Results, Name)
            continue;
        end

        AlgorithmResult = ExperimentResult.Results.(Name);

        if ~isstruct(AlgorithmResult) || ...
                ~isscalar(AlgorithmResult) || ...
                ~isfield(AlgorithmResult, 'ConvergenceData') || ...
                ~isstruct(AlgorithmResult.ConvergenceData) || ...
                ~isscalar(AlgorithmResult.ConvergenceData)

            error('buildConvergencePlotData:MissingConvergenceData', ...
                'Algorithm "%s" must contain a scalar ConvergenceData struct.', ...
                Name);
        end

        ConvergenceData = AlgorithmResult.ConvergenceData;

        for j = 1:numel(RequiredFields)
            if ~isfield(ConvergenceData, RequiredFields{j})
                error('buildConvergencePlotData:MissingConvergenceField', ...
                    'ConvergenceData for "%s" is missing field "%s".', ...
                    Name, RequiredFields{j});
            end
        end

        PlotData.(Name) = ConvergenceData;
    end
end