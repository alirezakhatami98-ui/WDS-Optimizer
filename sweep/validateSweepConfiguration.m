function validateSweepConfiguration(BaseOptions, ParameterName, Values)
%VALIDATESWEEPCONFIGURATION Validate the sweep setup before running.

    ValidParams = {'GA_Pc', 'GA_Pm', 'PSO_w', 'PSO_c1', 'PSO_c2', ...
                   'NS', 'MaxGen', 'NumberOfRuns', 'ExperimentSeed'};

    if ~ischar(ParameterName) || ~any(strcmp(ParameterName, ValidParams))
        error('sweep:InvalidParameter', ...
            'Unknown sweep parameter: %s', char(ParameterName));
    end

    if ~isnumeric(Values) || isempty(Values) || ...
            any(~isfinite(Values)) || ~isrow(Values)
        error('sweep:InvalidValues', ...
            'Values must be a non-empty finite numeric row vector.');
    end

    if numel(unique(Values)) ~= numel(Values)
        error('sweep:DuplicateValues', ...
            'Sweep values must be unique.');
    end

    switch ParameterName
        case {'GA_Pc', 'GA_Pm'}
            if any(Values < 0 | Values > 1)
                error('sweep:ValueOutOfRange', ...
                    '%s values must lie in [0, 1].', ParameterName);
            end

        case {'PSO_w', 'PSO_c1', 'PSO_c2'}
            if any(Values < 0)
                error('sweep:ValueOutOfRange', ...
                    '%s values must be non-negative.', ParameterName);
            end

        case {'NS', 'MaxGen', 'NumberOfRuns'}
            if any(Values < 1) || any(Values ~= fix(Values))
                error('sweep:ValueOutOfRange', ...
                    '%s values must be positive integers.', ParameterName);
            end

        case 'ExperimentSeed'
            if any(Values < 0) || any(Values > 2^32 - 1) || ...
                    any(Values ~= fix(Values))
                error('sweep:ValueOutOfRange', ...
                    'ExperimentSeed values must be integers in [0, 2^32-1].');
            end
    end

    % Algorithm must be enabled
    if any(strcmp(ParameterName, {'GA_Pc', 'GA_Pm'}))
        if ~any(strcmp(BaseOptions.Algorithms, 'GA'))
            error('sweep:AlgorithmNotEnabled', ...
                'GA must be enabled in Experiment Settings to sweep GA parameters.');
        end
    end

    if any(strcmp(ParameterName, {'PSO_w', 'PSO_c1', 'PSO_c2'}))
        if ~any(strcmp(BaseOptions.Algorithms, 'PSO'))
            error('sweep:AlgorithmNotEnabled', ...
                'PSO must be enabled in Experiment Settings to sweep PSO parameters.');
        end
    end
end