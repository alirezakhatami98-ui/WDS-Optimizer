function runValidationStudy(varargin)
% runValidationStudy  independent GA/PSO runs on the benchmark networks.
%
%   runValidationStudy                       baseline: 30 runs, NS=100, MaxGen=500
%   runValidationStudy('Tag','tuned','GA',struct('Pm',0.01))
%
% One MAT file per network/algorithm is written to studies/results/<Tag>/.
% Existing files are skipped, so an interrupted study can simply be restarted.

    p = inputParser;
    addParameter(p, 'Networks', {'2loops', 'hanoi'});
    addParameter(p, 'Algorithms', {'GA', 'PSO'});
    addParameter(p, 'NumRuns', 30);
    addParameter(p, 'NS', 100);
    addParameter(p, 'MaxGen', 500);
    addParameter(p, 'GA', struct());        % overrides for Config.GA fields
    addParameter(p, 'PSO', struct());       % overrides for Config.PSO fields
    addParameter(p, 'Seed', 2026);
    addParameter(p, 'Tag', 'baseline');
    addParameter(p, 'CacheMode', 'SharedExperiment');
    addParameter(p, 'Overwrite', false);
    parse(p, varargin{:});
    S = p.Results;

    studiesFolder = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(studiesFolder);

    originalPath = path;
    cleanupPath = onCleanup(@() path(originalPath)); %#ok<NASGU>
    addpath(projectRoot);
    addpath(fullfile(projectRoot, 'tests'));    % createTestEnvironment

    if isempty(which('runGA'))
        callSetup();
    end

    outFolder = fullfile(studiesFolder, 'results', S.Tag);
    if ~isfolder(outFolder)
        mkdir(outFolder);
    end

    for n = 1:numel(S.Networks)
        for a = 1:numel(S.Algorithms)

            net = S.Networks{n};
            alg = S.Algorithms{a};
            outFile = fullfile(outFolder, sprintf('%s_%s.mat', net, alg));

            if isfile(outFile) && ~S.Overwrite
                fprintf('[skip] %s / %s already done\n', net, alg);
                continue;
            end

            fprintf('\n===== %s / %s : %d runs =====\n', net, alg, S.NumRuns);
            runOne(net, alg, S, outFile);

        end
    end

    fprintf('\nStudy "%s" finished. Now run: analyzeValidationStudy(''%s'')\n', ...
        S.Tag, S.Tag);

end

function runOne(net, alg, S, outFile)

    Env = createTestEnvironment(net, [], [], S.NS, S.MaxGen);
    cleanupObj = onCleanup(Env.Release); %#ok<NASGU>

    Config = Env.Config;
    Config.Parallel.Enabled = false;

    Config.GA = mergeStruct(Config.GA, S.GA);
    Config.PSO = mergeStruct(Config.PSO, S.PSO);

    Opt = struct( ...
        'NumberOfRuns', S.NumRuns, ...
        'Algorithms', {{alg}}, ...
        'ExperimentSeed', S.Seed, ...
        'CacheMode', S.CacheMode);

    t0 = tic;
    ExperimentResult = runExperiment(Env.d, Env.Problem, Config, Opt);
    WallClock = toc(t0);

    Settings = S;
    Settings.Network = net;
    Settings.Algorithm = alg;
    Settings.GAEffective = Config.GA;
    Settings.PSOEffective = Config.PSO;
    Settings.Units = Env.Problem.Units;

    Info = struct('MatlabVersion', version, ...
        'Date', datestr(now), 'WallClockSeconds', WallClock);

    save(outFile, 'ExperimentResult', 'Settings', 'Info');
    fprintf('Saved %s (%.1f min)\n', outFile, WallClock / 60);

end

function A = mergeStruct(A, B)
    f = fieldnames(B);
    for i = 1:numel(f)
        A.(f{i}) = B.(f{i});
    end
end

function callSetup()
    setupWDSOptimizer;
end