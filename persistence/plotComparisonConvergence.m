function plotComparisonConvergence(ax, ExpA, ExpB, NameA, NameB)
%PLOTCOMPARISONCONVERGENCE Overlay mean convergence from two experiments.
%
%   A vs B distinguished by line style (solid vs dashed).
%   GA vs PSO distinguished by color (red vs blue).

    cla(ax, 'reset');
    hold(ax, 'on');

    AlgColors.GA  = [0.85 0.32 0.10];
    AlgColors.PSO = [0.00 0.45 0.74];

    Handles = gobjects(0);
    Labels  = {};

    AlgsA = ExpA.ExperimentResult.Configuration.Algorithms;
    AlgsB = ExpB.ExperimentResult.Configuration.Algorithms;

    for k = 1:numel(AlgsA)
        Alg = AlgsA{k};
        C = ExpA.ExperimentResult.Results.(Alg).ConvergenceData;
        if isempty(C.Generation), continue; end
        h = plot(ax, C.Generation, C.Mean, '-', ...
            'LineWidth', 2.2, 'Color', AlgColors.(Alg));
        Handles(end + 1) = h; %#ok<AGROW>
        Labels{end + 1} = sprintf('A: %s (%s, %d runs)', ...
            Alg, NameA, C.NumRuns(1)); %#ok<AGROW>
    end

    for k = 1:numel(AlgsB)
        Alg = AlgsB{k};
        C = ExpB.ExperimentResult.Results.(Alg).ConvergenceData;
        if isempty(C.Generation), continue; end
        h = plot(ax, C.Generation, C.Mean, '--', ...
            'LineWidth', 2.0, 'Color', AlgColors.(Alg));
        Handles(end + 1) = h; %#ok<AGROW>
        Labels{end + 1} = sprintf('B: %s (%s, %d runs)', ...
            Alg, NameB, C.NumRuns(1)); %#ok<AGROW>
    end

    hold(ax, 'off');

    if ~isempty(Handles)
        legend(ax, Handles, Labels, ...
            'Location', 'northeast', 'Interpreter', 'none');
    else
        text(ax, 0.5, 0.5, 'No convergence data to display', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center');
    end

    title(ax, 'Convergence Comparison (mean best cost per generation)');
    xlabel(ax, 'Generation / Iteration');
    ylabel(ax, 'Best Cost');
    grid(ax, 'on');
end