function validateOptimizationParameters(NS, MaxGen, Pmin, Vmax)

    if ~isnumeric(NS) || ~isscalar(NS)
        error('Validation:InvalidPopulationSize', ...
            'Population/swarm size must be a numeric scalar.');
    end

    if ~isfinite(NS)
        error('Validation:NonFinitePopulationSize', ...
            'Population/swarm size must be finite.');
    end

    if NS <= 0 || NS ~= floor(NS)
        error('Validation:InvalidPopulationSize', ...
            'Population/swarm size must be a positive integer.');
    end


    if ~isnumeric(MaxGen) || ~isscalar(MaxGen)
        error('Validation:InvalidMaxGenerations', ...
            'Maximum generations/iterations must be a numeric scalar.');
    end

    if ~isfinite(MaxGen)
        error('Validation:NonFiniteMaxGenerations', ...
            'Maximum generations/iterations must be finite.');
    end

    if MaxGen <= 0 || MaxGen ~= floor(MaxGen)
        error('Validation:InvalidMaxGenerations', ...
            'Maximum generations/iterations must be a positive integer.');
    end


    if ~isnumeric(Pmin) || ~isscalar(Pmin)
        error('Validation:InvalidMinimumPressure', ...
            'Minimum pressure must be a numeric scalar.');
    end

    if ~isfinite(Pmin)
        error('Validation:NonFiniteMinimumPressure', ...
            'Minimum pressure must be finite.');
    end


    if ~isnumeric(Vmax) || ~isscalar(Vmax)
        error('Validation:InvalidMaximumVelocity', ...
            'Maximum velocity must be a numeric scalar.');
    end

    if ~isfinite(Vmax)
        error('Validation:NonFiniteMaximumVelocity', ...
            'Maximum velocity must be finite.');
    end

    if Vmax <= 0
        error('Validation:NonPositiveMaximumVelocity', ...
            'Maximum velocity must be greater than zero.');
    end

end