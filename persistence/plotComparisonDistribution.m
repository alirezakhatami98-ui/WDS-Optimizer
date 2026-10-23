function plotComparisonDistribution(ax, ExpA, ExpB)
%PLOTCOMPARISONDISTRIBUTION Grouped boxplot of final costs (feasible runs).

    cla(ax, 'reset');

    AlgsA = ExpA.ExperimentResult.Configuration.Algorithms;
    AlgsB = ExpB.ExperimentResult.Configuration.Algorithms;
    AllAlgs = unique([AlgsA, AlgsB], 'stable');

    Values = [];
    Groups = strings(0, 1);

    for k = 1:numel(AllAlgs)
        Alg = AllAlgs{k};

        if any(strcmp(AlgsA, Alg))
            v = extractFeasibleCosts(ExpA.ExperimentResult.Results.(Alg).Runs);
            if ~isempty(v)
                Values = [Values; v]; %#ok<AGROW>
                Groups = [Groups; repmat("A:" + string(Alg), numel(v), 1)]; %#ok<AGROW>
            end
        end

        if any(strcmp(AlgsB, Alg))
            v = extractFeasibleCosts(ExpB.ExperimentResult.Results.(Alg).Runs);
            if ~isempty(v)
                Values = [Values; v]; %#ok<AGROW>
                Groups = [Groups; repmat("B:" + string(Alg), numel(v), 1)]; %#ok<AGROW>
            end
        end
    end

    if isempty(Values)
        text(ax, 0.5, 0.5, 'No feasible runs to compare', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center');
        title(ax, 'Final cost distribution');
        return;
    end

    % Stable category order: A algorithms first, then B, in the order
    % declared inside each experiment.
    CatOrder = strings(0, 1);
    for k = 1:numel(AlgsA)
        CatOrder(end + 1, 1) = "A:" + string(AlgsA{k}); %#ok<AGROW>
    end
    for k = 1:numel(AlgsB)
        CatOrder(end + 1, 1) = "B:" + string(AlgsB{k}); %#ok<AGROW>
    end
    CatOrder = CatOrder(ismember(CatOrder, unique(Groups)));

    boxchart(ax, categorical(Groups, cellstr(CatOrder)), Values);

    title(ax, 'Final cost distribution (feasible runs)');
    ylabel(ax, 'Cost');
    grid(ax, 'on');
end

function v = extractFeasibleCosts(Runs)
    Ok = strcmp({Runs.Status}, 'Success') & ...
        logical([Runs.Feasible]) & ...
        isfinite([Runs.Score]);
    v = [Runs(Ok).Score]';
end