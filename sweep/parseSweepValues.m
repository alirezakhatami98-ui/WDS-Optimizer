function values = parseSweepValues(rawStr)
%PARSESWEEPVALUES Parse a comma-separated list of numeric values.

    if ~ischar(rawStr) && ~(isstring(rawStr) && isscalar(rawStr))
        error('sweep:InvalidValues', ...
            'Values must be a comma-separated string.');
    end

    rawStr = char(rawStr);
    parts = strtrim(strsplit(rawStr, ','));
    parts = parts(~cellfun(@isempty, parts));

    if isempty(parts)
        error('sweep:InvalidValues', 'Please enter at least one value.');
    end

    values = zeros(1, numel(parts));

    for k = 1:numel(parts)
        v = str2double(parts{k});
        if isnan(v) || ~isfinite(v)
            error('sweep:InvalidValues', ...
                'Cannot parse "%s" as a finite number.', parts{k});
        end
        values(k) = v;
    end
end