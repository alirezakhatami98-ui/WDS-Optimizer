function pool = initializeParallelHydraulics(inpFile, numWorkers)

% initializeParallelHydraulics
% Create/reuse a local parallel pool and initialize one
% persistent EPANET object on each worker.
%
% Inputs:
%   inpFile     : temporary INP file used by current optimization
%   numWorkers  : requested number of workers
%
% Output:
%   pool        : active parallel pool

    if nargin < 2
        error('initializeParallelHydraulics:NotEnoughInputs', ...
            'inpFile and numWorkers are required.');
    end

    if numWorkers < 1 || numWorkers ~= floor(numWorkers)
        error('initializeParallelHydraulics:InvalidNumWorkers', ...
            'numWorkers must be a positive integer.');
    end

    % ---------------------------------------------------------
    % Create or reuse the requested local pool.
    % ---------------------------------------------------------

    pool = gcp('nocreate');

    if isempty(pool)

        pool = parpool('local', numWorkers);

    elseif pool.NumWorkers ~= numWorkers

        delete(pool);

        pool = parpool('local', numWorkers);

    end

    % ---------------------------------------------------------
    % Initialize one persistent EPANET object on each worker.
    % ---------------------------------------------------------

    spmd

        workerEpanetBatchEvaluate( ...
            'initialize', ...
            inpFile);

    end

end