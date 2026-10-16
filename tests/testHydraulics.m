function testHydraulics()

    checkHydraulics('2loops');
    checkHydraulics('hanoi');
    checkDomainSanity();

end

function checkHydraulics(netName)

    Env = createTestEnvironment(netName);
    cleanupObj = onCleanup(Env.Release); %#ok<NASGU>

    d = Env.d;
    Problem = Env.Problem;
    NP = Problem.NP;
    nVar = numel(Problem.VariablePipes);

    rng(11);

    for k = 1:50

        ind = randi(numel(Problem.D), nVar, 1);

        FullD = Problem.InitialD;
        FullD(Problem.VariablePipes) = Problem.D(ind);

        % New lifecycle versus the library's own solveCompleteHydraulics
        [Pj, V, conv] = runHydraulicSimulation( ...
            d, NP, FullD, Problem.JunctionIndices);

        assert(conv, '%s: random design %d did not converge.', netName, k);

        d.setLinkDiameter(1:NP, FullD');
        d.solveCompleteHydraulics();
        Pall = double(d.getNodePressure());
        Pref = Pall(Problem.JunctionIndices);
        Vref = double(abs(d.getLinkVelocity()));

        assert(max(abs(Pj - Pref)) < 1e-9 && max(abs(V - Vref)) < 1e-9, ...
            '%s: runHydraulicSimulation differs from solveCompleteHydraulics.', ...
            netName);

        % Final-results path must agree with the optimizer path
        [Pn, Vn, cn] = calculateHydraulicResults(d, FullD, NP);

        assert(cn && max(abs(Pn - Pj)) < 1e-9 && max(abs(Vn - V)) < 1e-9, ...
            '%s: calculateHydraulicResults differs.', netName);

    end

    % Forced non-convergence must be detected
    if ismethod(d, 'setOptionsMaxTrials')

        original = double(d.getOptionsMaxTrials());
        d.setOptionsMaxTrials(1);

        [~, ~, convForced] = runHydraulicSimulation( ...
            d, NP, FullD, Problem.JunctionIndices);

        d.setOptionsMaxTrials(original);

        assert(~convForced, ...
            '%s: non-convergence was not detected with MaxTrials = 1.', netName);

        [~, ~, convAgain] = runHydraulicSimulation( ...
            d, NP, FullD, Problem.JunctionIndices);

        assert(convAgain, '%s: MaxTrials was not restored.', netName);

    end

end

function checkDomainSanity()

    Env = createTestEnvironment('2loops');
    cleanupObj = onCleanup(Env.Release); %#ok<NASGU>

    d = Env.d;
    Problem = Env.Problem;
    nVar = numel(Problem.VariablePipes);
    nOpt = numel(Problem.D);

    % Largest diameters everywhere must be feasible; smallest must not.
    [~, vBig, fBig] = evaluateSolution(nOpt * ones(nVar, 1), Problem, d);
    assert(fBig && vBig == 0, 'All-largest design should be feasible.');

    [~, vSmall, fSmall] = evaluateSolution(ones(nVar, 1), Problem, d);
    assert(~fSmall && vSmall > 0, 'All-smallest design should be infeasible.');

    % evaluateSolution against an independent manual computation
    rng(3);

    for k = 1:20

        ind = randi(nOpt, nVar, 1);
        [c, v, f] = evaluateSolution(ind, Problem, d);

        FullD = Problem.InitialD;
        FullD(Problem.VariablePipes) = Problem.D(ind);

        [Pj, V, conv] = runHydraulicSimulation( ...
            d, Problem.NP, FullD, Problem.JunctionIndices);

        [v2, f2] = checkConstraints( ...
            Pj, V, Problem.Pmin, Problem.Vmax, conv);

        c2 = sum(Problem.L(Problem.VariablePipes) .* Problem.Cost(ind));

        assert(abs(c - c2) <= 1e-9 * max(1, abs(c2)) && v == v2 && f == f2);

    end

end