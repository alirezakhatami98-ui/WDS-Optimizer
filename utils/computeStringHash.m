function hash = computeStringHash(str)
% Compute the SHA-256 hex digest of a char array.

    if isempty(str)
        str = '';
    end

    md = java.security.MessageDigest.getInstance('SHA-256');
    bytes = md.digest(uint8(str));
    hash = sprintf('%02x', double(typecast(bytes, 'uint8')));
end