function nodeTable = createNodeResultsTable(NodePressures, Pmin, Units)

    if nargin < 3 || isempty(Units)
        Units.PressureUnit = 'm';
    end

    numNodes = numel(NodePressures);
    PressureStatus = cell(numNodes, 1);

    for k = 1:numNodes
        if NodePressures(k) < Pmin
            PressureStatus{k} = sprintf( ...
                'Violation (<%.1f %s)', Pmin, Units.PressureUnit);
        else
            PressureStatus{k} = 'Feasible (OK)';
        end
    end

    Node_ID = (1:numNodes)';
    Pressure = NodePressures(:);

    PressureName = matlab.lang.makeValidName( ...
        ['Pressure_' Units.PressureUnit]);

    nodeTable = table( ...
        Node_ID, ...
        Pressure, ...
        PressureStatus, ...
        'VariableNames', ...
        {'Node_ID', PressureName, 'Status'});

end