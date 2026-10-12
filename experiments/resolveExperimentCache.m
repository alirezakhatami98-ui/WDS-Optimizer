function [RunCache, SharedCache] = ...
    resolveExperimentCache(CacheMode, SharedCache)
%RESOLVEEXPERIMENTCACHE Resolve cache according to experiment cache mode.
%
% CacheMode:
%   'PerRun'          - Create a fresh cache for each run.
%   'SharedExperiment' - Reuse one cache across experiment runs.
%
% SharedCache is the experiment-scoped cache handle. Pass [] when
% no shared cache has been created yet.
%
% RunCache is the cache to pass to runGA or runPSO.

    if nargin < 2
        SharedCache = [];
    end

    % Validate CacheMode.
    if isstring(CacheMode) && isscalar(CacheMode)
        CacheMode = char(CacheMode);
    end

    if ~ischar(CacheMode) || ~isrow(CacheMode)
        error('resolveExperimentCache:InvalidCacheMode', ...
            'CacheMode must be PerRun or SharedExperiment.');
    end

    if strcmpi(CacheMode, 'PerRun')
        CacheMode = 'PerRun';
    elseif strcmpi(CacheMode, 'SharedExperiment')
        CacheMode = 'SharedExperiment';
    else
        error('resolveExperimentCache:InvalidCacheMode', ...
            'Unsupported CacheMode: %s. Use PerRun or SharedExperiment.', ...
            CacheMode);
    end

    % Accept only [] or a containers.Map object.
    % An empty containers.Map is still a valid cache object.
    if ~isa(SharedCache, 'containers.Map') && ~isempty(SharedCache)
        error('resolveExperimentCache:InvalidSharedCache', ...
            'SharedCache must be [] or a containers.Map object.');
    end

    switch CacheMode

        case 'PerRun'

            % A fresh cache for this run.
            RunCache = createEvaluationCache();

        case 'SharedExperiment'

            if isa(SharedCache, 'containers.Map')

                % Reuse the existing experiment-scoped cache.
                RunCache = SharedCache;

            else

                % Create the shared cache only once.
                SharedCache = createEvaluationCache();
                RunCache = SharedCache;

            end

    end

end