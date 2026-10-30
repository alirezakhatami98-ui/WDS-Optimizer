function [CI_Low, CI_High, PointCosts] = computeSweepPointCIs(SweepResult)
%COMPUTESWEEPPOINTCIS Bootstrap 95% CI of mean cost per successful point.
%
%   Returns per-point CI bounds and the raw cost vectors (for downstream
%   Kruskal-Wallis or similar). Loads each successful .wdsx once.

    Points = SweepResult.Points;
    N = numel(Points);
    CI_Low = nan(N, 1);
    CI_High = nan(N, 1);
    PointCosts = cell(N, 1);

    SweptAlg = sweepAlgForParam(SweepResult.Parameter);

    for k = 1:N
        if ~strcmp(Points(k).Status, 'Success'), continue; end
        if isempty(Points(k).WdsxPath) || ~isfile(Points(k).WdsxPath), continue; end
        try
            S = load(Points(k).WdsxPath, '-mat');
            if ~isfield(S, 'SavedExperiment'), continue; end
            E = S.SavedExperiment;

            if isempty(SweptAlg)
                Alg = E.Best.Algorithm;
            else
                Alg = SweptAlg;
            end
            if ~isfield(E.ExperimentResult.Results, Alg), continue; end

            Runs = E.ExperimentResult.Results.(Alg).Runs;
            Ok = strcmp({Runs.Status}, 'Success') & ...
                logical([Runs.Feasible]) & isfinite([Runs.Score]);
            costs = [Runs(Ok).Score]';
            PointCosts{k} = costs;

            if numel(costs) >= 3
                [CI_Low(k), CI_High(k)] = ...
                    bootstrapCI(costs, @mean, 0.05, 2000, 42);
            end
        catch
        end
    end
end

function alg = sweepAlgForParam(parameterName)
    if startsWith(parameterName, 'GA_')
        alg = 'GA';
    elseif startsWith(parameterName, 'PSO_')
        alg = 'PSO';
    else
        alg = '';
    end
end