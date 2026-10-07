function [Pj, Vpipes] = runHydraulicSimulation( ...
    d, NP, FullD, JunctionIndices)

    d.setLinkDiameter(1:NP, FullD');

    d.openHydraulicAnalysis();
    cleanupH = onCleanup(@() d.closeHydraulicAnalysis());

    d.initializeHydraulicAnalysis(10);
    d.runHydraulicAnalysis();

    P = double(d.getNodePressure());
    Pj = P(JunctionIndices);

    Vpipes = double(abs(d.getLinkVelocity()));

end