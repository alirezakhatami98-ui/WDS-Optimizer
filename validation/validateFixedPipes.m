function fixedPipes = validateFixedPipes(FixedPipeString, NP)

    % Empty input means that no pipes are fixed.
    fixedStr = strtrim(FixedPipeString);

    if isempty(fixedStr)
        fixedPipes = [];
        return;
    end

    % Convert comma-separated text into individual tokens.
    tokens = strsplit(fixedStr, ',');

    fixedPipes = zeros(1, numel(tokens));

    for i = 1:numel(tokens)

        token = strtrim(tokens{i});

        if isempty(token)
            error('Validation:InvalidFixedPipeFormat', ...
                'Fixed pipe IDs must be positive integers separated by commas.');
        end

        value = str2double(token);

        if ~isfinite(value) || value ~= floor(value)
            error('Validation:InvalidFixedPipeID', ...
                'Each fixed pipe ID must be a finite integer.');
        end

        if value < 1 || value > NP
            error('Validation:FixedPipeOutOfRange', ...
                'Fixed pipe ID %d is outside the valid range 1 to %d.', ...
                value, NP);
        end

        fixedPipes(i) = value;
    end

    % Duplicate pipe IDs are not allowed.
    if numel(unique(fixedPipes)) ~= numel(fixedPipes)
        error('Validation:DuplicateFixedPipeID', ...
            'Fixed pipe IDs must be unique.');
    end

    % Standardize the representation.
    fixedPipes = sort(fixedPipes);

end