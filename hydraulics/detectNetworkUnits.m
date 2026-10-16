function Units = detectNetworkUnits(d)
% Reads the unit system of a loaded EPANET network.
% Diameter and length units drive numeric conversions, so unknown values
% are an error. Pressure and velocity units are only used as labels, so
% unknown values fall back to the raw toolkit string.

    U = d.getUnits();

    Units.FlowUnit = char(d.getFlowUnits());

    if U.Units_SI_Metric == 1
        Units.System = 'SI';
    elseif U.Units_US_Customary == 1
        Units.System = 'US';
    else
        error('detectNetworkUnits:UnknownSystem', ...
            'Could not determine the unit system of the network.');
    end

    Units.DiameterUnit = mapUnit(U.LinkPipeDiameterUnits, ...
        {'millimeters', 'inches'}, {'mm', 'in'}, true);

    Units.LengthUnit = mapUnit(U.LinkLengthsUnits, ...
        {'meters', 'feet'}, {'m', 'ft'}, true);

    Units.PressureUnit = mapUnit(U.NodePressureUnits, ...
        {'meters', 'psi'}, {'m', 'psi'}, false);

    Units.VelocityUnit = mapUnit(U.LinkVelocityUnits, ...
        {'meters/sec', 'ft/sec'}, {'m/s', 'ft/s'}, false);

end

function label = mapUnit(raw, rawNames, labels, strict)

    key = lower(strtrim(char(raw)));
    idx = find(strcmp(key, rawNames), 1);

    if ~isempty(idx)
        label = labels{idx};
    elseif strict
        error('detectNetworkUnits:UnsupportedUnit', ...
            'Unsupported unit reported by EPANET: "%s".', char(raw));
    else
        label = char(raw);
    end

end