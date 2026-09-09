function cleanupEpanetObject(d)

    if isempty(d)
        return;
    end

    try
        d.unload();
    catch
        % Ignore cleanup errors.
    end

end