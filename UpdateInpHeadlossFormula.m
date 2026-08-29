function UpdateInpHeadlossFormula(inpFilePath, selectedFormula)

    switch selectedFormula
        case 'Hazen-Williams (HW)'
            codeStr = 'H-W';
        case 'Darcy-Weisbach (DW)'
            codeStr = 'D-W';
        case 'Manning (CM)'
            codeStr = 'C-M';
    end

    % Read lines from temporary INP file
    fid = fopen(inpFilePath, 'r');
    if fid == -1
        return;
    end

    lines = {};
    while ~feof(fid)
        lines{end+1} = fgetl(fid); %#ok<AGROW>
    end
    fclose(fid);

    % Replace or append HEADLOSS option
    found = false;

    for i = 1:numel(lines)
        if startsWith(strtrim(lines{i}), 'HEADLOSS', 'IgnoreCase', true)
            lines{i} = sprintf(' HEADLOSS           %s', codeStr);
            found = true;
            break;
        end
    end

    if ~found
        % Insert HEADLOSS under [OPTIONS] section
        for i = 1:numel(lines)
            if contains(lines{i}, '[OPTIONS]', 'IgnoreCase', true)
                lines = [lines(1:i); ...
                    {sprintf(' HEADLOSS           %s', codeStr)}; ...
                    lines(i+1:end)];
                break;
            end
        end
    end

    % Write modified content back to temporary INP file
    fid = fopen(inpFilePath, 'w');

    for i = 1:numel(lines)
        fprintf(fid, '%s\n', lines{i});
    end

    fclose(fid);

end