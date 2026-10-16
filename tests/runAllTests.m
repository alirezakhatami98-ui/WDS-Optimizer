function results = runAllTests(varargin)
% runAllTests                       run every test*.m in this folder
% runAllTests('SkipParallel', true) skip tests whose name contains "Parallel"
% runAllTests('Verbose', true)      show the output of each test

    p = inputParser;
    addParameter(p, 'SkipParallel', false, @islogical);
    addParameter(p, 'Verbose', false, @islogical);
    parse(p, varargin{:});
    opt = p.Results;

    testsFolder = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(testsFolder);

    originalPath = path;
    cleanupPath = onCleanup(@() path(originalPath)); %#ok<NASGU>
    addpath(projectRoot);
    addpath(testsFolder);

    if isempty(which('runGA'))
        callSetup();
    end

    if isempty(which('runGA'))
        error('runAllTests:SetupFailed', ...
            'Project functions are not on the path. Run setupWDSOptimizer first.');
    end

    files = dir(fullfile(testsFolder, 'test*.m'));
    names = sort(erase({files.name}, '.m'));

    n = numel(names);
    Status = strings(n, 1);
    Seconds = zeros(n, 1);
    Message = strings(n, 1);

    for i = 1:n

        name = names{i};

        if opt.SkipParallel && contains(lower(name), 'parallel')
            Status(i) = "SKIP";
            Message(i) = "skipped by option";
            fprintf('%-30s SKIP (option)\n', name);
            continue;
        end

        fprintf('%-30s ', name);
        t0 = tic;

        try
            if opt.Verbose
                fprintf('\n');
                feval(name);
            else
                evalc('feval(name);');
            end
            Status(i) = "PASS";
        catch ME
            if strcmp(ME.identifier, 'WDS:TestSkipped')
                Status(i) = "SKIP";
                Message(i) = string(ME.message);
            else
                Status(i) = "FAIL";
                if ~isempty(ME.stack)
                    Message(i) = string(sprintf('%s [%s, line %d]', ...
                        ME.message, ME.stack(1).name, ME.stack(1).line));
                else
                    Message(i) = string(ME.message);
                end
            end
        end

        Seconds(i) = toc(t0);
        fprintf('%s  (%.1f s)\n', Status(i), Seconds(i));

        if Status(i) ~= "PASS"
            fprintf('    -> %s\n', Message(i));
        end

    end

    nFail = sum(Status == "FAIL");

    fprintf('\nPASS: %d | FAIL: %d | SKIP: %d | total %.1f s\n', ...
        sum(Status == "PASS"), nFail, sum(Status == "SKIP"), sum(Seconds));

    if nFail == 0
        fprintf('ALL TESTS PASSED\n');
    else
        fprintf('SOME TESTS FAILED\n');
    end

    results = table(string(names(:)), Status, Seconds, Message, ...
        'VariableNames', {'Test', 'Status', 'Seconds', 'Message'});

    if nargout == 0
        clear results;
    end

end

function callSetup()
% Called from a local function so that a script that uses "clear"
% cannot wipe the runner's variables.
    setupWDSOptimizer;
end