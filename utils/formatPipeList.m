function s = formatPipeList(pipes)
    if isempty(pipes)
        s = '';
    else
        s = strjoin(arrayfun(@(x) num2str(x), pipes(:)', ...
            'UniformOutput', false), ', ');
    end
end