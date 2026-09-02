function Params = buildOptimizationParams( ...
    NS, Pmin, Vmax, FixedPipeString, NP, InitialD)

    fixedStr = strtrim(FixedPipeString);
    fixedPipes = [];

    if ~isempty(fixedStr)
        try
            fixedPipes = str2num(fixedStr); %#ok<ST2NM>
            fixedPipes = fixedPipes(fixedPipes >= 1 & fixedPipes <= NP);
        catch
            fixedPipes = [];
        end
    end

    Params.NS = NS;
    Params.Pmin = Pmin;
    Params.Vmax = Vmax;
    Params.FixedPipes = fixedPipes;
    Params.VariablePipes = setdiff(1:NP, fixedPipes);
    Params.InitialD = InitialD;

end