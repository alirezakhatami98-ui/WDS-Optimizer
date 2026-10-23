function diagnoseConvergence(Tag)
% Uses saved run histories only; no new optimization runs.

    if nargin < 1, Tag = 'baseline'; end

    folder = fullfile(fileparts(mfilename('fullpath')), 'results', Tag);
    files = dir(fullfile(folder, '*.mat'));
    assert(~isempty(files), 'No result files in %s', folder);

    checkpoints = [50 100 200 300 400 500];
    Colors.GA = [0.85 0.32 0.10];
    Colors.PSO = [0.00 0.45 0.74];

    items = struct('net', {}, 'alg', {}, 'G', {}, 'M', {}, 'Mn', {}, 'Mx', {});

    fprintf('\n===== Convergence diagnostics "%s" =====\n\n', Tag);

    for i = 1:numel(files)

        L = load(fullfile(folder, files(i).name));
        net = L.Settings.Network;
        alg = L.Settings.Algorithm;
        ref = referenceCost(net);

        R = L.ExperimentResult.Results.(alg);
        Dc = R.ConvergenceData;

        G = Dc.Generation(:);
        gapOf = @(x) 100 * (x(:) - ref) / ref;

        items(end+1) = struct('net', net, 'alg', alg, 'G', G, ...
            'M', gapOf(Dc.Mean), 'Mn', gapOf(Dc.Min), 'Mx', gapOf(Dc.Max)); %#ok<AGROW>

        % Mean gap at checkpoints
        fprintf('%s / %s\n  mean gap (%%) at generation:', net, alg);
        for c = checkpoints(checkpoints <= numel(G))
            fprintf('  %d: %.2f', c, gapOf(Dc.Mean(G == c)));
        end
        fprintf('\n');

        % Per-run stagnation measures
        Conv = collectConv(R.Runs);
        [nGen, nRuns] = size(Conv);

        lastImp = ones(1, nRuns);
        stillImproving = false(1, nRuns);
        tail = min(100, nGen - 1);

        for j = 1:nRuns
            k = find(diff(Conv(:, j)) < 0, 1, 'last');
            if ~isempty(k), lastImp(j) = k + 1; end
            stillImproving(j) = any(diff(Conv(end-tail:end, j)) < 0);
        end

        q = quantile(lastImp, [0.25 0.5 0.75]);

        fprintf(['  last improvement (generation): median %d  [IQR %d - %d] of %d\n' ...
                 '  runs still improving in the last %d generations: %d / %d\n\n'], ...
            round(q(2)), round(q(1)), round(q(3)), nGen, ...
            tail, sum(stillImproving), nRuns);

    end

    %% Figure
    nets = unique({items.net});

    fig = figure('Visible', 'off', 'Position', [100 100 1000 380]);
    tl = tiledlayout(fig, 1, numel(nets));

    for n = 1:numel(nets)

        ax = nexttile(tl);
        hold(ax, 'on');

        for k = find(strcmp({items.net}, nets{n}))

            it = items(k);
            col = Colors.(it.alg);

            fill(ax, [it.G; flipud(it.G)], [it.Mn; flipud(it.Mx)], col, ...
                'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
            plot(ax, it.G, it.M, 'LineWidth', 2, 'Color', col, ...
                'DisplayName', it.alg);

        end

        title(ax, nets{n});
        xlabel(ax, 'Generation / Iteration');
        ylabel(ax, 'Gap to reference (%)');
        ylim(ax, [0 30]);
        grid(ax, 'on');
        legend(ax, 'Location', 'northeast');

    end

    try
        exportgraphics(fig, fullfile(folder, 'convergence_diagnostic.png'), ...
            'Resolution', 150);
    catch
    end
    close(fig);

    fprintf('Saved convergence_diagnostic.png in %s\n', folder);

end

function Conv = collectConv(Runs)

    cols = {};

    for i = 1:numel(Runs)
        R = Runs(i);
        if strcmp(R.Status, 'Success') && isnumeric(R.Conv) && ~isempty(R.Conv)
            cols{end+1} = R.Conv(:); %#ok<AGROW>
        end
    end

    Conv = [cols{:}];

end