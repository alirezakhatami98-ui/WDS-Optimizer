function T = analyzeValidationStudy(Tag)
% analyzeValidationStudy  summary statistics, gap to reference, GA vs PSO test.

    if nargin < 1, Tag = 'baseline'; end

    studiesFolder = fileparts(mfilename('fullpath'));
    folder = fullfile(studiesFolder, 'results', Tag);

    files = dir(fullfile(folder, '*.mat'));
    assert(~isempty(files), 'No result files in %s', folder);

    rows = {};
    scoresByNet = struct();

    for i = 1:numel(files)

        L = load(fullfile(folder, files(i).name));
        net = L.Settings.Network;
        alg = L.Settings.Algorithm;
        Runs = L.ExperimentResult.Results.(alg).Runs;

        [score, feas, ok] = collectRuns(Runs);

        good = score(ok & feas);
        ref = referenceCost(net);

        nRuns = numel(Runs);
        nFailed = sum(~ok);
        nFeas = numel(good);

        if nFeas > 0
            gap = 100 * (good - ref) / ref;
            row = {net, alg, nRuns, nFailed, nFeas, ...
                min(good), median(good), mean(good), std(good), max(good), ...
                min(gap), median(gap), ...
                sum(gap <= 0.1), sum(gap <= 2)};
        else
            row = {net, alg, nRuns, nFailed, 0, ...
                NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0, 0};
        end

        rows(end+1, :) = row; %#ok<AGROW>

        key = matlab.lang.makeValidName([net '_' alg]);
        scoresByNet.(key) = good;

    end

    T = cell2table(rows, 'VariableNames', { ...
        'Network', 'Algorithm', 'Runs', 'Failed', 'Feasible', ...
        'Best', 'Median', 'Mean', 'Std', 'Worst', ...
        'BestGap_pct', 'MedianGap_pct', 'Within0p1pct', 'Within2pct'});

    T = sortrows(T, {'Network', 'Algorithm'});

    fprintf('\n===== Validation study "%s" =====\n', Tag);
    fprintf(['Gap = 100*(cost - reference)/reference over feasible runs.\n' ...
             'Within0p1pct / Within2pct = number of feasible runs inside that gap.\n\n']);

    disp(T);

    %% GA versus PSO (unpaired)
    nets = unique(T.Network);

    for k = 1:numel(nets)

        kGA = matlab.lang.makeValidName([nets{k} '_GA']);
        kPSO = matlab.lang.makeValidName([nets{k} '_PSO']);

        if ~isfield(scoresByNet, kGA) || ~isfield(scoresByNet, kPSO)
            continue;
        end

        x = scoresByNet.(kGA);
        y = scoresByNet.(kPSO);

        if isempty(x) || isempty(y)
            continue;
        end

        % Vargha-Delaney A12: probability that a GA run is cheaper than a
        % PSO run (ties count one half). 0.5 means no difference.
        A12 = mean(x(:) < y(:)', 'all') + 0.5 * mean(x(:) == y(:)', 'all');

        pText = 'n/a';
        if exist('ranksum', 'file') == 2
            try
                pText = sprintf('%.4g', ranksum(x, y));
            catch
            end
        end

        fprintf('%s: GA vs PSO  A12 = %.2f (GA cheaper), rank-sum p = %s\n', ...
            nets{k}, A12, pText);

    end

    %% Save summary and figure
    writetable(T, fullfile(folder, 'summary.csv'));

    try
        fig = figure('Visible', 'off', 'Position', [100 100 900 380]);
        tl = tiledlayout(fig, 1, numel(nets));

        for k = 1:numel(nets)

            ax = nexttile(tl);
            vals = []; grp = strings(0, 1);

            for alg = {'GA', 'PSO'}
                key = matlab.lang.makeValidName([nets{k} '_' alg{1}]);
                if isfield(scoresByNet, key)
                    g = 100 * (scoresByNet.(key) - referenceCost(nets{k})) ...
                        / referenceCost(nets{k});
                    vals = [vals; g(:)]; %#ok<AGROW>
                    grp = [grp; repmat(string(alg{1}), numel(g), 1)]; %#ok<AGROW>
                end
            end

            if ~isempty(vals)
                boxchart(ax, categorical(grp), vals);
            end
            title(ax, nets{k});
            ylabel(ax, 'Gap to reference (%)');
            grid(ax, 'on');

        end

        exportgraphics(fig, fullfile(folder, 'gap_boxplot.png'), 'Resolution', 150);
        close(fig);
    catch
    end

    fprintf('\nSaved summary.csv and gap_boxplot.png in %s\n', folder);

    if nargout == 0
        clear T;
    end

end

function [score, feas, ok] = collectRuns(Runs)

    n = numel(Runs);
    score = nan(n, 1);
    feas = false(n, 1);
    ok = false(n, 1);

    for i = 1:n
        R = Runs(i);
        ok(i) = strcmp(R.Status, 'Success') && isnumeric(R.Score) && ...
            isscalar(R.Score) && isfinite(R.Score);
        if ok(i)
            score(i) = R.Score;
            feas(i) = logical(R.Feasible);
        end
    end

end