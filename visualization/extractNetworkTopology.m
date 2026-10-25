function Network = extractNetworkTopology(d)
%EXTRACTNETWORKTOPOLOGY Read node coordinates and link topology from EPANET.
%
% Returns an empty struct() when coordinates are unavailable so that
% callers can fall back to a v1 snapshot.

    Network = struct();

    try
        NC = d.getNodeCoordinates();
    catch
        return;
    end

    if isempty(NC) || numel(NC) < 2 || isempty(NC{1}) || all(isnan(NC{1}(:)))
        return;
    end

    X = NC{1}(:);
    Y = NC{2}(:);

    if numel(X) ~= numel(Y) || isempty(X)
        return;
    end

    Network.NodeIDs         = d.getNodeNameID();
    Network.NodeCoordinates = [X, Y];
    Network.NodeTypes       = d.getNodeType();
    Network.LinkIDs         = d.getLinkNameID();
    Network.LinkTypes       = d.getLinkType();
    Network.LinkNodes       = d.getLinkNodesIndex();
end