function exportSweepReportFigures(SweepResult, figDir, ~)
%EXPORTSWEEPREPORTFIGURES Generate PNG figures for the sweep report.

    if ~isfolder(figDir), mkdir(figDir); end

    Points = SweepResult.Points;
    N      = numel(Points);
    Ok     = strcmp({Points.Status}, 'Success');
    X      = [Points.Value];
    Best   = [Points.BestScore];
    Mean   = [Points.MeanCost];
    Std    = [Points.StdCost];
    Time   = [Points.MeanTime];

    ParamLabel = strrep(SweepResult.Parameter, '_', ' ');
    SweptAlg   = sweptAlgorithmName(SweepResult.Parameter);

    % ---- Trend 1: Best cost ----
    fig = figure('Visible', 'off', 'Color', 'w', ...
        'Position', [100 100 800 500]);
    ax = gca;
    if any(Ok)
        plot(ax, X(Ok), Best(Ok), '-o', 'LineWidth', 2, ...
            'MarkerFaceColor', [0.85 0.32 0.10], ...
            'Color', [0.85 0.32 0.10]);
    end
    title(ax, 'Best Cost vs Parameter');
    xlabel(ax, ParamLabel);
    ylabel(ax, 'Best Cost');
    grid(ax, 'on');
    exportgraphics(fig, fullfile(figDir, 'trend_best_cost.png'), ...
        'Resolution', 300);
    close(fig);

    % ---- Trend 2: Mean cost ± Std ----
    fig = figure('Visible', 'off', 'Color', 'w', ...
        'Position', [100 100 800 500]);
    ax = gca;
    hold(ax, 'on');
    valid = Ok & isfinite(Mean);
    if any(valid)
        plot(ax, X(valid), Mean(valid), '-s', 'LineWidth', 2, ...
            'MarkerFaceColor', [0.00 0.45 0.74], ...
            'Color', [0.00 0.45 0.74]);
        errValid = valid & isfinite(Std);
        if any(errValid)
            errorbar(ax, X(errValid), Mean(errValid), Std(errValid), ...
                'LineStyle', 'none', 'Color', [0 0.45 0.74 0.5]);
        end
    end
    hold(ax, 'off');
    title(ax, 'Mean Cost vs Parameter (with std)');
    xlabel(ax, ParamLabel);
    ylabel(ax, 'Mean Cost');
    grid(ax, 'on');
    exportgraphics(fig, fullfile(figDir, 'trend_mean_cost.png'), ...
        'Resolution', 300);
    close(fig);

    % ---- Trend 3: Mean time ----
    fig = figure('Visible', 'off', 'Color', 'w', ...
        'Position', [100 100 800 500]);
    ax = gca;
    if any(Ok)
        plot(ax, X(Ok), Time(Ok), '-d', 'LineWidth', 2, ...
            'MarkerFaceColor', [0.47 0.67 0.19], ...
            'Color', [0.47 0.67 0.19]);
    end
    title(ax, 'Mean Time vs Parameter');
    xlabel(ax, ParamLabel);
    ylabel(ax, 'Mean Time (s)');
    grid(ax, 'on');
    exportgraphics(fig, fullfile(figDir, 'trend_time.png'), ...
        'Resolution', 300);
    close(fig);

    % ---- Cache loaded experiments ----
    [Exps, Loaded] = loadAllPointExperiments(Points);

    % ---- Convergence overlay ----
    fig = figure('Visible', 'off', 'Color', 'w', ...
        'Position', [100 100 850 520]);
    ax = gca;
    hold(ax, 'on');
    Colors = lines(N);
    Handles = gobjects(0);
    Labels = {};
    for k = 1:N
        if ~Loaded(k), continue; end
        C = getConvergenceForPoint(Exps{k}, SweptAlg);
        if isempty(C) || isempty(C.Generation), continue; end
        h = plot(ax, C.Generation, C.Mean, '-', 'LineWidth', 2.0, ...
            'Color', Colors(k, :));
        Handles(end + 1) = h; %#ok<AGROW>
        Labels{end + 1} = sprintf('%s = %g', ...
            ParamLabel, Points(k).Value); %#ok<AGROW>
    end
    hold(ax, 'off');
    if ~isempty(Handles)
        legend(ax, Handles, Labels, 'Location', 'northeast', ...
            'Interpreter', 'none');
    end
    title(ax, 'Convergence Overlay (mean best cost per generation)');
    xlabel(ax, 'Generation / Iteration');
    ylabel(ax, 'Best Cost');
    grid(ax, 'on');
    exportgraphics(fig, fullfile(figDir, 'convergence_overlay.png'), ...
        'Resolution', 300);
    close(fig);

    % ---- Distribution overlay ----
    Values = [];
    Groups = strings(0, 1);
    for k = 1:N
        if ~Loaded(k), continue; end
        s = getPointScores(Exps{k}, SweptAlg);
        if isempty(s), continue; end
        Values = [Values; s]; %#ok<AGROW>
        Groups = [Groups; repmat( ...
            string(sprintf('%s = %g', ParamLabel, Points(k).Value)), ...
            numel(s), 1)]; %#ok<AGROW>
    end

    if ~isempty(Values)
        fig = figure('Visible', 'off', 'Color', 'w', ...
            'Position', [100 100 900 520]);
        ax = gca;
        boxchart(ax, categorical(Groups, unique(Groups, 'stable')), Values);
        title(ax, 'Final Cost Distribution per Point (feasible runs)');
        ylabel(ax, 'Cost');
        grid(ax, 'on');
        try
            xtickangle(ax, 30);
        catch
        end
        exportgraphics(fig, fullfile(figDir, 'distribution_overlay.png'), ...
            'Resolution', 300);
        close(fig);
    end

    % ---- Network map (best point) ----
    BestExp = loadBestPointExperiment(SweepResult);
    if ~isempty(BestExp) && isfield(BestExp, 'Network') && ...
            ~isempty(BestExp.Network) && ...
            isfield(BestExp.Network, 'NodeIDs') && ...
            isfield(BestExp, 'Best') && isfield(BestExp.Best, 'Position')
        try
            fig = figure('Visible', 'off', 'Color', 'w', ...
                'Position', [100 100 900 700]);
            ax = gca;
            Hydraulics.NodePressures  = BestExp.Hydraulics.NodePressures;
            Hydraulics.PipeVelocities = BestExp.Hydraulics.PipeVelocities;
            Hydraulics.Converged      = BestExp.Hydraulics.Converged;
            Options.Mode = 'velocity';
            plotNetworkMap(ax, BestExp.Network, Hydraulics, ...
                BestExp.Best.Position, BestExp.Problem, Options);
            exportgraphics(fig, fullfile(figDir, 'network_map.png'), ...
                'Resolution', 300);
            close(fig);
        catch
        end
    end
end

% ------------------------------------------------------------------------

function alg = sweptAlgorithmName(parameterName)
    if startsWith(parameterName, 'GA_')
        alg = 'GA';
    elseif startsWith(parameterName, 'PSO_')
        alg = 'PSO';
    else
        alg = '';
    end
end

function [Exps, Loaded] = loadAllPointExperiments(Points)
    N = numel(Points);
    Exps = cell(N, 1);
    Loaded = false(N, 1);
    for k = 1:N
        P = Points(k);
        if ~strcmp(P.Status, 'Success'), continue; end
        if isempty(P.WdsxPath) || ~isfile(P.WdsxPath), continue; end
        try
            S = load(P.WdsxPath, '-mat');
            if isfield(S, 'SavedExperiment')
                Exps{k} = S.SavedExperiment;
                Loaded(k) = true;
            end
        catch
        end
    end
end

function BestExp = loadBestPointExperiment(SweepResult)
    Points = SweepResult.Points;
    Ok = strcmp({Points.Status}, 'Success');
    Feasible = Ok & logical([Points.BestFeasible]);
    if any(Feasible)
        candidates = find(Feasible);
    elseif any(Ok)
        candidates = find(Ok);
    else
        BestExp = [];
        return;
    end
    scores = [Points(candidates).BestScore];
    [~, localBest] = min(scores);
    bestIdx = candidates(localBest);
    P = Points(bestIdx);
    BestExp = [];
    if isempty(P.WdsxPath) || ~isfile(P.WdsxPath), return; end
    try
        S = load(P.WdsxPath, '-mat');
        if isfield(S, 'SavedExperiment')
            BestExp = S.SavedExperiment;
        end
    catch
    end
end

function C = getConvergenceForPoint(E, SweptAlg)
    if ~isempty(SweptAlg) && isfield(E.ExperimentResult.Results, SweptAlg)
        C = E.ExperimentResult.Results.(SweptAlg).ConvergenceData;
    else
        C = E.ExperimentResult.Results.(E.Best.Algorithm).ConvergenceData;
    end
end

function scores = getPointScores(E, SweptAlg)
    if isempty(SweptAlg)
        algs = E.ExperimentResult.Configuration.Algorithms;
    else
        algs = {SweptAlg};
    end
    scores = [];
    for a = 1:numel(algs)
        if ~isfield(E.ExperimentResult.Results, algs{a}), continue; end
        Runs = E.ExperimentResult.Results.(algs{a}).Runs;
        Ok = strcmp({Runs.Status}, 'Success') & ...
            logical([Runs.Feasible]) & isfinite([Runs.Score]);
        s = [Runs(Ok).Score]';
        scores = [scores; s]; %#ok<AGROW>
    end
end