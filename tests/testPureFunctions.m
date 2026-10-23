function testPureFunctions()

    root = fileparts(fileparts(mfilename('fullpath')));

    %% checkConstraints
    [v, f] = checkConstraints([40; 40], [1; 1], 30, 2.5);
    assert(v == 0 && f);

    [v, f] = checkConstraints([15; 40], [5; 1], 30, 2.5);
    assert(abs(v - 0.75) < 1e-12 && ~f);

    [v, f] = checkConstraints([40; NaN], [1; 1], 30, 2.5);
    assert(v == 1e8 && ~f);

    [v, f] = checkConstraints([40; 40], [1; Inf], 30, 2.5);
    assert(v == 1e8 && ~f);

    [v, f] = checkConstraints([40; 40], [1; 1], 30, 2.5, false);
    assert(v == 1e8 && ~f);

    [v, f] = checkConstraints([40; 40], [1; 1], 30, 2.5, true);
    assert(v == 0 && f);

    %% calculateCostFromIndices (hand-computed values)
    Cost = [10; 20; 30];
    L = [100; 200; 300];

    assert(calculateCostFromIndices([1; 2], [1 2], Cost, L) == 5000);
    assert(calculateCostFromIndices([3; 2], [1 3], Cost, L) == 9000);
    assert(calculateCostFromIndices([3; 2], [1; 3], Cost, L) == 9000);
    assert(calculateCostFromIndices([3 2], [1 3], Cost.', L.') == 9000);
    expectError(@() calculateCostFromIndices( ...
        [1; 2; 3], [1 2], Cost, L), 'SizeMismatch');

    %% sortDiameterOptions
    [d, c, r] = sortDiameterOptions([30; 10; 20], [300; 100; 200]);
    assert(isequal(d, [10; 20; 30]) && isequal(c, [100; 200; 300]) && r);

    [~, ~, r] = sortDiameterOptions([10; 20; 30], [100; 200; 300]);
    assert(~r);

    lastwarn('');
    sortDiameterOptions([1; 2; 3], [10; 5; 20]);
    [~, id] = lastwarn;
    assert(strcmp(id, 'sortDiameterOptions:NonMonotoneCost'));

    expectError(@() sortDiameterOptions([1; 2], [1; 2; 3]), 'SizeMismatch');

    %% convertDiameterUnits
    x = [1; 2.5; 24];
    assert(isequal(convertDiameterUnits(x, 'in', 'in'), x));
    assert(isequal(convertDiameterUnits(x, 'mm', 'mm'), x));
    assert(isequal(convertDiameterUnits(x, 'in', 'mm'), x * 25.4));
    back = convertDiameterUnits(convertDiameterUnits(x, 'in', 'mm'), 'mm', 'in');
    assert(max(abs(back - x)) < 1e-12);
    expectError(@() convertDiameterUnits(x, 'cm', 'mm'), 'InvalidUnit');

    %% loadOptimizationData on the project networks
    nets = {'2loops', 'hanoi'};

    for n = 1:numel(nets)

        DFile = fullfile(root, 'networks', nets{n}, 'D.txt');
        CostFile = fullfile(root, 'networks', nets{n}, 'Cost.txt');

        [Din1, Cost1, D1] = loadOptimizationData(DFile, CostFile);
        [Din2, Cost2, D2] = loadOptimizationData(DFile, CostFile, 'in', 'mm');

        assert(isequal(Din1, Din2) && isequal(Cost1, Cost2) && isequal(D1, D2));
        assert(isequal(D1, Din1 * 25.4));
        assert(issorted(Din1));

        % A wrongly declared diameter-file unit must be rejected.
        expectError(@() loadOptimizationData( ...
            DFile, CostFile, 'mm', 'mm'), 'ImplausibleDiameters');
        expectError(@() loadOptimizationData( ...
            DFile, CostFile, 'mm', 'in'), 'ImplausibleDiameters');

    end

    %% Unsorted input files are reordered together
    fD = [tempname '.txt'];
    fC = [tempname '.txt'];
    cleanupFiles = onCleanup(@() deleteFiles({fD, fC})); %#ok<NASGU>

    x = [24; 12; 1];  save(fD, 'x', '-ascii');
    x = [30; 20; 10]; save(fC, 'x', '-ascii');

    ws = warning('off', 'loadOptimizationData:DiameterOptionsReordered');
    restoreWarning = onCleanup(@() warning(ws)); %#ok<NASGU>

    [Din, Cost, D] = loadOptimizationData(fD, fC, 'in', 'mm');
    assert(isequal(Din, [1; 12; 24]) && isequal(Cost, [10; 20; 30]));
    assert(isequal(D, Din * 25.4));

    %% selectionTournament
    rng(1);
    cost5 = [100; 200; 300; 400; 500];
    idx = selectionTournament(cost5, zeros(5, 1), 20000, 3);
    share = histcounts(idx, 1:6) / 20000;
    assert(abs(share(1) - (1 - 0.8^3)) < 0.02, 'Best individual share is wrong.');
    assert(abs(share(5) - 0.2^3) < 0.01, 'Worst individual share is wrong.');

    % Feasible beats infeasible even when it costs more
    idx = selectionTournament([1000; 1], [0; 5], 20000, 3);
    assert(abs(mean(idx == 1) - (1 - 0.5^3)) < 0.02);

    % Among infeasible designs the smaller violation wins
    idx = selectionTournament([1; 1000], [9; 2], 20000, 3);
    assert(abs(mean(idx == 2) - (1 - 0.5^3)) < 0.02);

end

function expectError(fcn, idPart)
    try
        fcn();
    catch ME
        assert(contains(ME.identifier, idPart), ...
            'Expected error id containing "%s", got "%s".', ...
            idPart, ME.identifier);
        return;
    end
    error('Expected an error containing "%s", but none was thrown.', idPart);
end

function deleteFiles(files)
    for i = 1:numel(files)
        if isfile(files{i}), delete(files{i}); end
    end
end