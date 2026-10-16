function testUnitsAndTables()

    root = fileparts(fileparts(mfilename('fullpath')));

    %% Unit detection
    expectedSI = struct('FlowUnit', 'LPS', 'System', 'SI', ...
        'DiameterUnit', 'mm', 'LengthUnit', 'm', ...
        'PressureUnit', 'm', 'VelocityUnit', 'm/s');

    expectedUS = struct('FlowUnit', 'GPM', 'System', 'US', ...
        'DiameterUnit', 'in', 'LengthUnit', 'ft', ...
        'PressureUnit', 'psi', 'VelocityUnit', 'ft/s');

    assert(isequal(detectNetworkUnitsFromFile(fullfile( ...
        root, 'networks', '2loops', '2Loops.inp')), expectedSI));

    assert(isequal(detectNetworkUnitsFromFile(fullfile( ...
        root, 'networks', 'hanoi', 'Hanoi.inp')), expectedSI));

    extra = dir(fullfile(root, '**', 'Net1.inp'));

    if isempty(extra)
        warning('testUnitsAndTables:NoNet1', ...
            'Net1.inp not found: US-units check skipped.');
    else
        assert(isequal(detectNetworkUnitsFromFile( ...
            fullfile(extra(1).folder, extra(1).name)), expectedUS));
    end

    %% Result tables
    SI = struct('DiameterUnit', 'mm', 'VelocityUnit', 'm/s', 'PressureUnit', 'm');
    US = struct('DiameterUnit', 'in', 'VelocityUnit', 'ft/s', 'PressureUnit', 'psi');

    T = createPipeResultsTable(3, [100; 200; 300], [1; 2; 3]);
    assert(isequal(T.Properties.VariableNames, ...
        {'Pipe_ID', 'Diameter_mm', 'Velocity_m_s'}));

    T = createPipeResultsTable(3, [4; 6; 8], [1; 2; 3], SI);
    assert(isequal(T.Properties.VariableNames, ...
        {'Pipe_ID', 'Diameter_mm', 'Velocity_m_s'}));

    T = createPipeResultsTable(3, [4; 6; 8], [1; 2; 3], US);
    assert(isequal(T.Properties.VariableNames, ...
        {'Pipe_ID', 'Diameter_in', 'Velocity_ft_s'}));

    T = createNodeResultsTable([10; 50], 30);
    assert(strcmp(T.Properties.VariableNames{2}, 'Pressure_m'));

    T = createNodeResultsTable([10; 50], 20, US);
    assert(strcmp(T.Properties.VariableNames{2}, 'Pressure_psi'));
    assert(contains(T.Status{1}, 'psi') && strcmp(T.Status{2}, 'Feasible (OK)'));

    %% Excel export
    ER.Metadata.ExperimentID = 'unit-test';
    ER.Configuration = struct('Algorithms', {{'GA'}}, 'NumberOfRuns', 1, ...
        'ExperimentSeed', 1, 'CacheMode', 'PerRun', 'NS', 10, ...
        'MaxGen', 5, 'Pmin', 20, 'Vmax', 10);
    ER.Results.GA.ConvergenceData.Generation = [];

    Units = US;
    Units.FlowUnit = 'GPM';
    Units.System = 'US';
    Units.LengthUnit = 'ft';
    Units.DiameterFileUnit = 'in';

    Dummy = table(1, 'VariableNames', {'x'});

    f1 = [tempname '.xlsx'];
    f2 = [tempname '.xlsx'];
    cleanupFiles = onCleanup(@() deleteFiles({f1, f2})); %#ok<NASGU>

    exportResultsToExcel(Dummy, Dummy, f1, ER, Dummy, Dummy, Units);
    params = string(readtable(f1, 'Sheet', 'Experiment_Settings').Parameter);
    assert(any(params == "Pmin (psi)") && any(params == "Vmax (ft/s)"));
    assert(any(params == "Flow units") && ...
        any(params == "Diameter file (D.txt) unit"));

    % Legacy call without Units still works.
    exportResultsToExcel(Dummy, Dummy, f2, ER, Dummy, Dummy);
    params = string(readtable(f2, 'Sheet', 'Experiment_Settings').Parameter);
    assert(any(params == "Pmin"));

end

function deleteFiles(files)
    for i = 1:numel(files)
        if isfile(files{i}), delete(files{i}); end
    end
end