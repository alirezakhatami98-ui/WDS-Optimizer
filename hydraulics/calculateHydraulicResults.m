function [NodePressures, PipeVelocities, Converged] = ...
    calculateHydraulicResults(d, Position, NP)

    % Uses the same hydraulic evaluation as the optimizer, so the
    % reported results follow the same convergence rule and precision.
    JunctionIndices = find(strcmpi(d.getNodeType(), 'JUNCTION'));

    [NodePressures, PipeVelocities, Converged] = ...
        runHydraulicSimulation(d, NP, Position(:), JunctionIndices);

end