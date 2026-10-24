function plotSweepTrends(parent, SweepResult)
%PLOTSWEEPTRENDS Three trend plots of best/mean cost and time vs value.

    g = uigridlayout(parent, [1 3]);
    g.Padding = [0 0 0 0];
    g.ColumnSpacing = 6;

    Points = SweepResult.Points;
    Status = {Points.Status};

    Ok   = strcmp(Status, 'Success');
    X    = [Points.Value];
    Best = [Points.BestScore];
    Mean = [Points.MeanCost];
    Std  = [Points.StdCost];
    Time = [Points.MeanTime];

    % --- Best cost ---
    ax1 = uiaxes(g);
    if any(Ok)
        plot(ax1, X(Ok), Best(Ok), '-o', 'LineWidth', 2, ...
            'MarkerFaceColor', [0.85 0.32 0.10], ...
            'Color', [0.85 0.32 0.10]);
    end
    title(ax1, 'Best Cost vs Parameter');
    xlabel(ax1, strrep(SweepResult.Parameter, '_', ' '));
    ylabel(ax1, 'Best Cost');
    grid(ax1, 'on');

    % --- Mean cost ± std ---
    ax2 = uiaxes(g);
    if any(Ok)
        hold(ax2, 'on');
        valid = Ok & isfinite(Mean);
        plot(ax2, X(valid), Mean(valid), '-s', 'LineWidth', 2, ...
            'MarkerFaceColor', [0.00 0.45 0.74], ...
            'Color', [0.00 0.45 0.74]);
        % Error bars only where Std is finite
        errValid = valid & isfinite(Std);
        if any(errValid)
            errorbar(ax2, X(errValid), Mean(errValid), Std(errValid), ...
                'LineStyle', 'none', 'Color', [0.00 0.45 0.74 0.5]);
        end
        hold(ax2, 'off');
    end
    title(ax2, 'Mean Cost vs Parameter');
    xlabel(ax2, strrep(SweepResult.Parameter, '_', ' '));
    ylabel(ax2, 'Mean Cost');
    grid(ax2, 'on');

    % --- Mean time ---
    ax3 = uiaxes(g);
    if any(Ok)
        plot(ax3, X(Ok), Time(Ok), '-d', 'LineWidth', 2, ...
            'MarkerFaceColor', [0.47 0.67 0.19], ...
            'Color', [0.47 0.67 0.19]);
    end
    title(ax3, 'Mean Time vs Parameter');
    xlabel(ax3, strrep(SweepResult.Parameter, '_', ' '));
    ylabel(ax3, 'Mean Time (s)');
    grid(ax3, 'on');
end