function [cost, viol, feas, Cache] = evaluatePopulation( ...
    Pop, Problem, d, Cache, Parallel)

    NS = size(Pop, 2);

    cost = zeros(NS, 1);
    viol = zeros(NS, 1);
    feas = false(NS, 1);

    % Default: sequential evaluation
    if nargin < 5 || isempty(Parallel)
        Parallel.Enabled = false;
    end

    % -------------------------------------------------------------
    % Step 1: Identify Cache HITs and MISSes
    % -------------------------------------------------------------

    MissIndices = [];
    MissCandidates = [];
    MissKeys = {};

    for i = 1:NS

        ind = Pop(:, i);

        key = sprintf('%d_', ind);

        if isKey(Cache, key)

            Value = Cache(key);

            cost(i) = Value(1);
            viol(i) = Value(2);
            feas(i) = Value(3);

        else

            MissIndices(end+1) = i; %#ok<AGROW>
            MissCandidates(:, end+1) = ind; %#ok<AGROW>
            MissKeys{end+1} = key; %#ok<AGROW>

        end
    end

    % -------------------------------------------------------------
    % Step 2: Return immediately if everything was cached
    % -------------------------------------------------------------

    if isempty(MissIndices)
        return;
    end

    % -------------------------------------------------------------
    % Step 3: Evaluate MISSes
    % -------------------------------------------------------------

    NumMisses = numel(MissIndices);

    if Parallel.Enabled

        if ~isfield(Parallel, 'NumWorkers') || ...
           isempty(Parallel.NumWorkers)

            error('evaluatePopulation:MissingNumWorkers', ...
                'Parallel.NumWorkers is required when parallel evaluation is enabled.');

        end

        % Hydraulic evaluation is performed by persistent
        % worker-local EPANET objects.
        [Pj, Vpipes] = evaluateParallelHydraulics( ...
            MissCandidates, ...
            Problem);

        % Cost and constraints remain in the main process.
        for k = 1:NumMisses

            i = MissIndices(k);

            FullD = Problem.InitialD;
            FullD(Problem.VariablePipes) = ...
                Problem.D(MissCandidates(:,k));

            cost(i) = calculateCost( ...
                FullD, ...
                Problem.VariablePipes, ...
                Problem.Din, ...
                Problem.Cost, ...
                Problem.L);

            [viol(i), feas(i)] = checkConstraints( ...
                Pj(:,k), ...
                Vpipes(:,k), ...
                Problem.Pmin, ...
                Problem.Vmax);

            Cache(MissKeys{k}) = ...
                [cost(i), viol(i), feas(i)];

        end

    else

        % Existing sequential evaluation path.
        for k = 1:NumMisses

            i = MissIndices(k);

            [cost(i), viol(i), feas(i)] = ...
                evaluateSolution( ...
                    MissCandidates(:,k), ...
                    Problem, ...
                    d);

            Cache(MissKeys{k}) = ...
                [cost(i), viol(i), feas(i)];

        end
    end

end