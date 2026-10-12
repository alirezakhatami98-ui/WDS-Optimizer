function ComparisonData = buildAlgorithmComparisonData(ExperimentResult)
%BUILDALGORITHMCOMPARISONDATA Build a unified algorithm comparison output.
%
% ComparisonData = buildAlgorithmComparisonData(ExperimentResult)
%
% Output fields:
%   Summary         - Full algorithm statistics table
%   CostComparison  - Cost comparison table
%   TimeComparison  - Runtime comparison table
%
% Existing builders are reused to avoid duplicated calculations.

    if ~isstruct(ExperimentResult) || ...
            ~isscalar(ExperimentResult) || ...
            ~isfield(ExperimentResult, 'Results') || ...
            ~isstruct(ExperimentResult.Results) || ...
            ~isscalar(ExperimentResult.Results)

        error('buildAlgorithmComparisonData:InvalidExperimentResult', ...
            'ExperimentResult must contain a scalar Results struct.');
    end

    ComparisonData = struct();

    ComparisonData.Summary = ...
        buildAlgorithmSummaryTable(ExperimentResult);

    ComparisonData.CostComparison = ...
        buildCostComparisonData(ExperimentResult);

    ComparisonData.TimeComparison = ...
        buildExecutionTimeComparisonData(ExperimentResult);
end