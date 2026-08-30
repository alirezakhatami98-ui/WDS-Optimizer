function nodeTable = createNodeResultsTable(NodePressures, Pmin)

    numNodes = numel(NodePressures);
    PressureStatus = cell(numNodes, 1);

    for k = 1:numNodes
        if NodePressures(k) < Pmin
            PressureStatus{k} = sprintf('Violation (<%.1fm)', Pmin);
        else
            PressureStatus{k} = 'Feasible (OK)';
        end
    end

    Node_ID = (1:numNodes)';
    Pressure_m = NodePressures(:);

    nodeTable = table( ...
        Node_ID, ...
        Pressure_m, ...
        PressureStatus, ...
        'VariableNames', ...
        {'Node_ID', 'Pressure_m', 'Status'});

end