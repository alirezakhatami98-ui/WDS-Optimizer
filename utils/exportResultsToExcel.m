function exportResultsToExcel(pipeTable, nodeTable, fileName, ...
    ExperimentResult, SummaryTable, RunsTable, Units)
%EXPORTRESULTSTOEXCEL Export best-design results and experiment data.
%
% The last three arguments are optional. When they are supplied, the
% workbook also contains experiment settings, per-algorithm statistics,
% every individual run, and the aggregated convergence histories.

    % uiputfile has already asked the user to confirm overwriting.
    if isfile(fileName)
        delete(fileName);
    end

    writetable(pipeTable, fileName, 'Sheet', 'Pipe_Optimization');
    writetable(nodeTable, fileName, 'Sheet', 'Hydraulic_Nodes');

    if nargin < 6 || isempty(ExperimentResult)
        return;
    end

    C = ExperimentResult.Configuration;

    HasUnits = nargin >= 7 && ~isempty(Units);

    if HasUnits
        PminName = sprintf('Pmin (%s)', Units.PressureUnit);
        VmaxName = sprintf('Vmax (%s)', Units.VelocityUnit);
    else
        PminName = 'Pmin';
        VmaxName = 'Vmax';
    end

    Parameter = { ...
        'Experiment ID'; 'Algorithms'; 'Runs per algorithm'; ...
        'Experiment seed'; 'Cache mode'; 'Population / Swarm'; ...
        'Max generations / iterations'; PminName; VmaxName};

    Value = { ...
        ExperimentResult.Metadata.ExperimentID; ...
        strjoin(C.Algorithms, ' + '); ...
        num2str(C.NumberOfRuns); ...
        sprintf('%.0f', C.ExperimentSeed); ...
        C.CacheMode; ...
        num2str(C.NS); ...
        num2str(C.MaxGen); ...
        num2str(C.Pmin); ...
        num2str(C.Vmax)};

    if HasUnits

        Parameter = [Parameter; { ...
            'Flow units'; 'Unit system'; ...
            'Network pipe diameter unit'; 'Cost.txt is cost per'}];

        Value = [Value; { ...
            Units.FlowUnit; Units.System; ...
            Units.DiameterUnit; ...
            sprintf('1 %s of pipe', Units.LengthUnit)}];

        if isfield(Units, 'DiameterFileUnit')
            Parameter = [Parameter; {'Diameter file (D.txt) unit'}];
            Value = [Value; {Units.DiameterFileUnit}];
        end

    end

    writetable(table(Parameter, Value), fileName, ...
        'Sheet', 'Experiment_Settings');

    writetable(SummaryTable, fileName, 'Sheet', 'Experiment_Summary');
    writetable(RunsTable, fileName, 'Sheet', 'All_Runs');

    for a = 1:numel(C.Algorithms)

        Name = C.Algorithms{a};
        D = ExperimentResult.Results.(Name).ConvergenceData;

        if isempty(D.Generation)
            continue;
        end

        T = table(D.Generation, D.Mean, D.Std, D.Median, ...
            D.Min, D.Max, ...
            'VariableNames', ...
            {'Generation', 'Mean', 'Std', 'Median', 'Min', 'Max'});

        writetable(T, fileName, 'Sheet', ['Convergence_' Name]);

    end

end
