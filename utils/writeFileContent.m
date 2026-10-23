function writeFileContent(filePath, content)
% Write a text string as raw bytes (no newline translation).

    fid = fopen(filePath, 'wb');
    if fid < 0
        error('WDS:FileWrite', ...
            'Cannot open file for writing: %s', filePath);
    end
    cleaner = onCleanup(@() fclose(fid)); 

    fwrite(fid, uint8(content), 'uint8');
end