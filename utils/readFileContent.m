function content = readFileContent(filePath)
% Read a text file preserving exact bytes (no CRLF/LF conversion).

    fid = fopen(filePath, 'rb');
    if fid < 0
        error('WDS:FileRead', ...
            'Cannot open file for reading: %s', filePath);
    end
    cleaner = onCleanup(@() fclose(fid)); 

    content = fread(fid, Inf, 'uint8=>char')';
end