function validateOptimizationData(D, Cost)

    if isempty(D)
        error('Validation:EmptyDiameterData', ...
            'Diameter data is empty.');
    end

    if ~isnumeric(D)
        error('Validation:InvalidDiameterType', ...
            'Diameter data must be numeric.');
    end

    if any(~isfinite(D))
        error('Validation:NonFiniteDiameterData', ...
            'Diameter data must contain only finite values.');
    end

    if any(D <= 0)
        error('Validation:NonPositiveDiameterData', ...
            'All diameter values must be greater than zero.');
    end

    if numel(unique(D)) ~= numel(D)
        error('Validation:DuplicateDiameterData', ...
            'Diameter values must be unique.');
    end


    if isempty(Cost)
        error('Validation:EmptyCostData', ...
            'Cost data is empty.');
    end

    if ~isnumeric(Cost)
        error('Validation:InvalidCostType', ...
            'Cost data must be numeric.');
    end

    if any(~isfinite(Cost))
        error('Validation:NonFiniteCostData', ...
            'Cost data must contain only finite values.');
    end

    if any(Cost <= 0)
        error('Validation:NonPositiveCostData', ...
            'All cost values must be greater than zero.');
    end


    if numel(D) ~= numel(Cost)
        error('Validation:DiameterCostMismatch', ...
            'Diameter and cost data must contain the same number of values.');
    end

end