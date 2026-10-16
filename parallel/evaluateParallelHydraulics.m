function [Pj, Vpipes, Converged] = evaluateParallelHydraulics( ...
    Candidates, Problem)

% evaluateParallelHydraulics
% Evaluate multiple candidate solutions using already initialized,
% persistent worker-local EPANET objects.
%
% Inputs:
%   Candidates  : [Nvars x N] candidate chromosome matrix
%   Problem     : unified optimization problem structure
%
% Outputs:
%   Pj          : [Njunctions x N] junction pressures
%   Vpipes      : [NP x N] pipe velocities
%
% Important:
%   - This function performs hydraulic evaluation only.
%   - Cost and constraint calculations remain in the main process.
%   - Each worker owns its own persistent EPANET object.
%   - Worker EPANET objects are initialized outside this function.
%   - Worker EPANET objects are reused across calls.
%   - Parallel pool lifecycle is managed outside this function.

    if nargin < 2
        error('evaluateParallelHydraulics:NotEnoughInputs', ...
            'Candidates and Problem are required.');
    end

    if isempty(Candidates)
        Pj = zeros(numel(Problem.JunctionIndices), 0);
        Vpipes = zeros(Problem.NP, 0);
        Converged = true(1, 0);
        return;
    end

    % -------------------------------------------------------------
    % Use the already existing parallel pool.
    % -------------------------------------------------------------
    pool = gcp('nocreate');

    if isempty(pool)
        error('evaluateParallelHydraulics:NoPool', ...
            ['No parallel pool is active. ', ...
             'Call initializeParallelHydraulics first.']);
    end

    numWorkers = pool.NumWorkers;

    NumEvaluations = size(Candidates, 2);
    NumJunctions = numel(Problem.JunctionIndices);
    NP = Problem.NP;

    % -------------------------------------------------------------
    % Distribute candidate indices between workers.
    %
    % Round-robin distribution is used because it was already
    % validated in the Phase 7 prototype.
    % -------------------------------------------------------------
    localIndices = cell(numWorkers, 1);

    for w = 1:numWorkers
        localIndices{w} = w:numWorkers:NumEvaluations;
    end

    % -------------------------------------------------------------
    % Evaluate each worker's local candidate batch.
    %
    % EPANET initialization is intentionally NOT performed here.
    % Each worker must already own a persistent EPANET object.
    % -------------------------------------------------------------
    spmd

        idx = localIndices{labindex};

        if isempty(idx)

            resultP = zeros(NumJunctions, 0);
            resultV = zeros(NP, 0);
            resultC = true(1, 0);
            resultIdx = zeros(1, 0);

        else

            localCandidates = Candidates(:, idx);

            [resultP, resultV, resultC] = ...
                workerEpanetBatchEvaluate( ...
                    'evaluate', ...
                    localCandidates, ...
                    Problem.D);

            resultIdx = idx;

        end

    end

    % -------------------------------------------------------------
    % Reconstruct the original candidate ordering in the
    % main process.
    % -------------------------------------------------------------
    Pj = zeros(NumJunctions, NumEvaluations);
    Vpipes = zeros(NP, NumEvaluations);
    Converged = true(1, NumEvaluations);

    for w = 1:numWorkers

        idx = resultIdx{w};

        if isempty(idx)
            continue;
        end

        Pj(:, idx) = resultP{w};
        Vpipes(:, idx) = resultV{w};
        Converged(idx) = resultC{w};

    end

end