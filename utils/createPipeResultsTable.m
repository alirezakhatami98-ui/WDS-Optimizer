function pipeTable = createPipeResultsTable( ...
    NP, OptimalDiameters, PipeVelocities, Units)

    % Without Units the legacy metric column names are used.
    if nargin < 4 || isempty(Units)
        Units.DiameterUnit = 'mm';
        Units.VelocityUnit = 'm/s';
    end

    Pipe_ID = (1:NP)';
    Diameter = OptimalDiameters(:);
    Velocity = PipeVelocities(:);

    DiameterName = matlab.lang.makeValidName( ...
        ['Diameter_' Units.DiameterUnit]);

    VelocityName = matlab.lang.makeValidName( ...
        ['Velocity_' strrep(Units.VelocityUnit, '/', '_')]);

    pipeTable = table( ...
        Pipe_ID, ...
        Diameter, ...
        Velocity, ...
        'VariableNames', ...
        {'Pipe_ID', DiameterName, VelocityName});

end