function [Pj, Vpipes] = runHydraulicSimulation( ...
    d, NP, FullD, JunctionIndices)

    d.setLinkDiameter(1:NP, FullD');
    d.solveCompleteHydraulics();

    P = double(d.getNodePressure());
    Pj = P(JunctionIndices);

    Vpipes = double(abs(d.getLinkVelocity()));

end