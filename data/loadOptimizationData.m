function [Din, Cost, D] = loadOptimizationData( ...
    DFilePath, CostFilePath, DiameterFileUnit, NetworkDiameterUnit)
% Din  : diameters as written in the file (in DiameterFileUnit), ascending
% Cost : unit cost of each option, same order as Din
% D    : diameters converted to the network pipe-diameter unit
%
% Without the last two arguments the legacy convention is used:
% diameter file in inches, network in millimeters.

    if nargin < 3 || isempty(DiameterFileUnit)
        DiameterFileUnit = 'in';
    end

    if nargin < 4 || isempty(NetworkDiameterUnit)
        NetworkDiameterUnit = 'mm';
    end

    Din = load(DFilePath);
    Cost = load(CostFilePath);

    [Din, Cost, wasReordered] = sortDiameterOptions(Din, Cost);

    if wasReordered
        warning('loadOptimizationData:DiameterOptionsReordered', ...
            ['Diameter options were not in ascending order. ', ...
             'Diameters and costs were reordered together.']);
    end

    D = convertDiameterUnits(Din, DiameterFileUnit, NetworkDiameterUnit);

    checkDiameterPlausibility(D, NetworkDiameterUnit);

end