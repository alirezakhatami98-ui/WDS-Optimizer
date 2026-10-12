function ConvergenceData = aggregateConvergenceData(Runs)
%AGGREGATECONVERGENCEDATA Aggregate convergence histories across runs.
%
%   ConvergenceData = aggregateConvergenceData(Runs)
%
%   Required fields in Runs:
%       Status
%       Conv
%
%   Successful runs must contain finite numeric convergence vectors
%   of equal length.
%
%   Output fields:
%       Generation, Mean, Std, Median, Min, Max, NumRuns

    if ~isstruct(Runs)
        error('aggregateConvergenceData:InvalidRuns', ...
            'Runs must be a struct array.');
    end

    RequiredFields = {'Status', 'Conv'};

    for k = 1:numel(RequiredFields)
        if ~isfield(Runs, RequiredFields{k})
            error('aggregateConvergenceData:MissingField', ...
                'Runs is missing required field "%s".', ...
                RequiredFields{k});
        end
    end

    SuccessfulIndices = false(numel(Runs), 1);

    for k = 1:numel(Runs)
        Status = Runs(k).Status;

        if isstring(Status) && isscalar(Status)
            Status = char(Status);
        end

        if ~ischar(Status)
            error('aggregateConvergenceData:InvalidStatus', ...
                'Run %d has an invalid Status value.', k);
        end

        SuccessfulIndices(k) = strcmpi(Status, 'Success');
    end

    SuccessfulRuns = Runs(SuccessfulIndices);
    NumberOfSuccessfulRuns = numel(SuccessfulRuns);

    if NumberOfSuccessfulRuns == 0
        ConvergenceData = struct( ...
            'Generation', zeros(0, 1), ...
            'Mean', zeros(0, 1), ...
            'Std', zeros(0, 1), ...
            'Median', zeros(0, 1), ...
            'Min', zeros(0, 1), ...
            'Max', zeros(0, 1), ...
            'NumRuns', zeros(0, 1));
        return;
    end

    FirstConv = SuccessfulRuns(1).Conv;

    if ~isnumeric(FirstConv) || ~isreal(FirstConv) || ...
            ~isvector(FirstConv) || isempty(FirstConv) || ...
            any(~isfinite(FirstConv(:)))
        error('aggregateConvergenceData:InvalidConv', ...
            'Run 1 must contain a nonempty finite numeric convergence vector.');
    end

    FirstConv = FirstConv(:);
    NumberOfGenerations = numel(FirstConv);

    ConvergenceMatrix = zeros( ...
        NumberOfGenerations, NumberOfSuccessfulRuns);

    for k = 1:NumberOfSuccessfulRuns
        Conv = SuccessfulRuns(k).Conv;

        if ~isnumeric(Conv) || ~isreal(Conv) || ...
                ~isvector(Conv) || isempty(Conv) || ...
                any(~isfinite(Conv(:)))
            error('aggregateConvergenceData:InvalidConv', ...
                'Successful run %d has an invalid convergence vector.', k);
        end

        Conv = Conv(:);

        if numel(Conv) ~= NumberOfGenerations
            error('aggregateConvergenceData:InconsistentLength', ...
                ['Successful runs must have equal convergence lengths. ' ...
                 'Run 1 has %d generations; run %d has %d.'], ...
                NumberOfGenerations, k, numel(Conv));
        end

        ConvergenceMatrix(:, k) = Conv;
    end

    ConvergenceData.Generation = (1:NumberOfGenerations)';

    ConvergenceData.Mean = mean(ConvergenceMatrix, 2);
    ConvergenceData.Median = median(ConvergenceMatrix, 2);
    ConvergenceData.Min = min(ConvergenceMatrix, [], 2);
    ConvergenceData.Max = max(ConvergenceMatrix, [], 2);

    if NumberOfSuccessfulRuns > 1
        ConvergenceData.Std = std(ConvergenceMatrix, 0, 2);
    else
        ConvergenceData.Std = nan(NumberOfGenerations, 1);
    end

    ConvergenceData.NumRuns = ...
        repmat(NumberOfSuccessfulRuns, NumberOfGenerations, 1);

end