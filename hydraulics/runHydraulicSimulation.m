function [Pj, Vpipes, Converged] = runHydraulicSimulation( ...
    d, NP, FullD, JunctionIndices)

    d.setLinkDiameter(1:NP, FullD');

    MaxTrials = double(d.getOptionsMaxTrials());

    d.openHydraulicAnalysis();
    cleanupH = onCleanup(@() d.closeHydraulicAnalysis());

    d.initializeHydraulicAnalysis(10);
    d.runHydraulicAnalysis();

    P = double(d.getNodePressure());
    Pj = P(JunctionIndices);

    Vpipes = double(abs(d.getLinkVelocity()));

    % Convergence is judged from the solver statistics (while the
    % analysis is still open). The return value of runHydraulicAnalysis
    % is the simulation time in this toolkit, not an error code.
    Stat = d.getStatistic();
    Converged = double(Stat.Iterations) < MaxTrials;

end