function T = compareStudies(net, alg, tags)
% Compare several study tags for one network/algorithm.
% The first tag is the control.

    base = fullfile(fileparts(mfilename('fullpath')), 'results');
    ref = referenceCost(net);

    rows = {};
    ctrl = [];

    for i = 1:numel(tags)

        L = load(fullfile(base, tags{i}, sprintf('%s_%s.mat', net, alg)));
        [score, feas, ok] = collectRuns(L.ExperimentResult.Results.(alg).Runs);

        good = score(ok & feas);
        gap = 100 * (good - ref) / ref;

        A12 = NaN;
        p = NaN;

        if i == 1
            ctrl = good;
        elseif ~isempty(good) && ~isempty(ctrl)
            % Probability that a run of this variant is cheaper than a control run
            A12 = mean(good(:) < ctrl(:)', 'all') + ...
                  0.5 * mean(good(:) == ctrl(:)', 'all');
            if exist('ranksum', 'file') == 2
                try, p = ranksum(good, ctrl); catch, end
            end
        end

        rows(end+1, :) = {tags{i}, numel(score), numel(good), ...
            min(good), median(gap), mean(gap), sum(gap <= 2), A12, p}; %#ok<AGROW>

    end

    T = cell2table(rows, 'VariableNames', {'Tag', 'Runs', 'Feasible', ...
        'Best', 'MedianGap_pct', 'MeanGap_pct', 'Within2pct', ...
        'A12_vs_first', 'p_vs_first'});

    fprintf('\n%s / %s (first row = control, A12 > 0.5 means cheaper than control)\n', net, alg);
    disp(T);

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