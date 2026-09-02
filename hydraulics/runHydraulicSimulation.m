function [Pj, Vpipes] = runHydraulicSimulation(d, NP, FullD)

    d.setLinkDiameter(1:NP, FullD');
    d.solveCompleteHydraulics();

    P = d.getNodePressure();
    Pj = P(strcmpi(d.getNodeType(), 'JUNCTION'));

    Vpipes = abs(d.getLinkVelocity());

end