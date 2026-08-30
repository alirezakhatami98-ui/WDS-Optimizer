function [NodePressures, PipeVelocities] = ...
    calculateHydraulicResults(d, Position, NP)

    d.setLinkDiameter(1:NP, Position);
    d.solveCompleteHydraulics();

    P = d.getNodePressure();
    junctions = strcmpi(d.getNodeType(), 'JUNCTION');

    NodePressures = P(junctions);
    PipeVelocities = abs(d.getLinkVelocity());

end