function exportReportFigures(Exp, figDir)
%EXPORTREPORTFIGURES Generate PNG figures for the reproducibility report.

    if ~isfolder(figDir)
        mkdir(figDir);
    end

    Units = Exp.Problem.Units;
    if isempty(Units)
        Units.DiameterUnit = 'mm';
        Units.VelocityUnit = 'm/s';
        Units.PressureUnit = 'm';
    end

    Algorithms = Exp.ExperimentResult.Configuration.Algorithms;

    % ---- Convergence per algorithm ----
    for a = 1:numel(Algorithms)
        Alg = Algorithms{a};
        C = Exp.ExperimentResult.Results.(Alg).ConvergenceData;
        if isempty(C.Generation)
            continue;
        end

        fig = figure('Visible', 'off', 'Color', 'w', ...
            'Position', [100 100 800 500]);
        ax = gca;   % ← جایگزین ax = axes(fig);

        hold(ax, 'on');
        fill(ax, [C.Generation; flipud(C.Generation)], ...
            [C.Min; flipud(C.Max)], [0 0.4470 0.7410], ...
            'FaceAlpha', 0.15, 'EdgeColor', 'none');
        plot(ax, C.Generation, C.Mean, 'LineWidth', 2.2, ...
            'Color', [0 0.4470 0.7410]);
        hold(ax, 'off');

        title(ax, sprintf('%s Convergence (%d runs)', ...
            Alg, C.NumRuns(1)));
        xlabel(ax, 'Generation / Iteration');
        ylabel(ax, 'Best Cost');
        grid(ax, 'on');

        exportgraphics(fig, fullfile(figDir, ...
            sprintf('convergence_%s.png', Alg)), 'Resolution', 300);
        close(fig);
    end

    % ---- Pressure profile ----
    if ~isempty(Exp.Hydraulics.NodePressures)
        fig = figure('Visible', 'off', 'Color', 'w', ...
            'Position', [100 100 1000 450]);
        ax = axes(fig);
        bar(ax, 1:numel(Exp.Hydraulics.NodePressures), ...
            Exp.Hydraulics.NodePressures, 0.6, ...
            'FaceColor', [0 0.45 0.74]);
        hold(ax, 'on');
        yline(ax, Exp.Problem.Pmin, '--r', ...
            sprintf('Pmin (%.1f %s)', Exp.Problem.Pmin, Units.PressureUnit), ...
            'LineWidth', 1.5);
        hold(ax, 'off');
        title(ax, 'Node Pressure Profile');
        xlabel(ax, 'Node ID');
        ylabel(ax, sprintf('Pressure (%s)', Units.PressureUnit));
        grid(ax, 'on');
        exportgraphics(fig, fullfile(figDir, 'pressure_profile.png'), ...
            'Resolution', 300);
        close(fig);
    end

    % ---- Velocity profile ----
    if ~isempty(Exp.Hydraulics.PipeVelocities)
        fig = figure('Visible', 'off', 'Color', 'w', ...
            'Position', [100 100 1000 450]);
        ax = axes(fig);
        bar(ax, 1:numel(Exp.Hydraulics.PipeVelocities), ...
            Exp.Hydraulics.PipeVelocities, 0.6, ...
            'FaceColor', [0.47 0.67 0.19]);
        hold(ax, 'on');
        yline(ax, Exp.Problem.Vmax, '--r', ...
            sprintf('Vmax (%.1f %s)', Exp.Problem.Vmax, Units.VelocityUnit), ...
            'LineWidth', 1.5);
        hold(ax, 'off');
        title(ax, 'Pipe Velocity Profile');
        xlabel(ax, 'Pipe ID');
        ylabel(ax, sprintf('Velocity (%s)', Units.VelocityUnit));
        grid(ax, 'on');
        exportgraphics(fig, fullfile(figDir, 'velocity_profile.png'), ...
            'Resolution', 300);
        close(fig);
    end

    % ---- Cost distribution ----
    Values = [];
    Groups = strings(0, 1);

    for a = 1:numel(Algorithms)
        Alg = Algorithms{a};
        Runs = Exp.ExperimentResult.Results.(Alg).Runs;
        Ok = strcmp({Runs.Status}, 'Success') & ...
            logical([Runs.Feasible]) & ...
            isfinite([Runs.Score]);
        v = [Runs(Ok).Score]';
        if ~isempty(v)
            Values = [Values; v]; %#ok<AGROW>
            Groups = [Groups; repmat(string(Alg), numel(v), 1)]; %#ok<AGROW>
        end
    end

    if ~isempty(Values)
        fig = figure('Visible', 'off', 'Color', 'w', ...
            'Position', [100 100 700 450]);
        ax = axes(fig);
        boxchart(ax, categorical(Groups, string(Algorithms)), Values);
        title(ax, 'Final Cost Distribution (feasible runs)');
        ylabel(ax, 'Cost');
        grid(ax, 'on');
        exportgraphics(fig, fullfile(figDir, 'cost_distribution.png'), ...
            'Resolution', 300);
        close(fig);
    end
end