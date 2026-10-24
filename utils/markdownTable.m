function md = markdownTable(Headers, Data)

    Headers = string(Headers(:)');
    nCols = numel(Headers);
    md = strings(0, 1);

    md(end + 1, 1) = "| " + strjoin(Headers, " | ") + " |";
    md(end + 1, 1) = "|" + strjoin(repmat("---", 1, nCols), "|") + "|";

    for r = 1:size(Data, 1)
        row = strings(1, nCols);
        for c = 1:nCols
            v = Data{r, c};
            if ischar(v) || (isstring(v) && isscalar(v))
                row(c) = string(v);
            elseif isempty(v)
                row(c) = "";
            else
                row(c) = string(num2str(v));
            end
        end
        md(end + 1, 1) = "| " + strjoin(row, " | ") + " |"; %#ok<AGROW>
    end
end