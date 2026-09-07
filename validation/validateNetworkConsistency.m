function validateNetworkConsistency( ...
    NP, L, InitialD, Din, D, Cost, FixedPipes, VariablePipes)

    % Validate number of pipes
    if ~isscalar(NP) || ~isnumeric(NP) || ~isfinite(NP) || NP < 1
        error('NetworkValidation:InvalidNP', ...
            'Number of pipes (NP) must be a positive finite scalar.');
    end

    % Validate network-derived data
    if numel(L) ~= NP
        error('NetworkValidation:LengthMismatch', ...
            'Number of pipe lengths (%d) does not match NP (%d).', ...
            numel(L), NP);
    end

    % Validate pipe lengths
    if any(~isfinite(L)) || any(L <= 0)
        error('NetworkValidation:InvalidPipeLengths', ...
            'All pipe lengths must be finite and greater than zero.');
    end

    if numel(InitialD) ~= NP
        error('NetworkValidation:InitialDiameterMismatch', ...
            'Number of initial diameters (%d) does not match NP (%d).', ...
            numel(InitialD), NP);
    end

    % Validate initial pipe diameters
    if any(~isfinite(InitialD)) || any(InitialD <= 0)
        error('NetworkValidation:InvalidInitialDiameters', ...
            'All initial pipe diameters must be finite and greater than zero.');
    end

    % Validate candidate diameter data
    if numel(Din) ~= numel(D)
        error('NetworkValidation:DiameterDataMismatch', ...
            'Number of Din values (%d) does not match number of D values (%d).', ...
            numel(Din), numel(D));
    end

    % Validate diameter-cost mapping
    if numel(D) ~= numel(Cost)
        error('NetworkValidation:DiameterCostMismatch', ...
            'Number of candidate diameters (%d) does not match number of cost values (%d).', ...
            numel(D), numel(Cost));
    end

    % Validate Fixed Pipes
    if any(FixedPipes < 1) || any(FixedPipes > NP) || ...
            any(FixedPipes ~= floor(FixedPipes))
        error('NetworkValidation:InvalidFixedPipes', ...
            'Fixed pipe indices must be integers between 1 and NP.');
    end

    % Validate Variable Pipes
    if any(VariablePipes < 1) || any(VariablePipes > NP) || ...
            any(VariablePipes ~= floor(VariablePipes))
        error('NetworkValidation:InvalidVariablePipes', ...
            'Variable pipe indices must be integers between 1 and NP.');
    end

    % Fixed and variable pipes must not overlap
    if ~isempty(intersect(FixedPipes, VariablePipes))
        error('NetworkValidation:PipeOverlap', ...
            'Fixed and variable pipe sets must not overlap.');
    end

    % Together they must cover all pipes
    allPipes = sort([FixedPipes(:); VariablePipes(:)]);

    if ~isequal(allPipes, (1:NP)')
        error('NetworkValidation:PipeCoverage', ...
            'Fixed and variable pipes must together cover all pipe indices.');
    end

end