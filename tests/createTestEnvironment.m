function Env = createTestEnvironment(NetworkName, Pmin, Vmax, NS, MaxGen)
% Builds the same objects as WDS_Optimizer_App/PrepareEnvironment.
% Env.Release() frees the EPANET object and the temporary INP file.

    if nargin < 1 || isempty(NetworkName), NetworkName = '2loops'; end

    switch lower(NetworkName)
        case '2loops'
            folder = '2loops'; inpName = '2Loops.inp'; defaultVmax = 2.5;
        case 'hanoi'
            folder = 'hanoi'; inpName = 'Hanoi.inp'; defaultVmax = 15;
        otherwise
            error('createTestEnvironment:UnknownNetwork', ...
                'Unknown network "%s".', NetworkName);
    end

    if nargin < 2 || isempty(Pmin), Pmin = 30; end
    if nargin < 3 || isempty(Vmax), Vmax = defaultVmax; end
    if nargin < 4 || isempty(NS), NS = 10; end
    if nargin < 5 || isempty(MaxGen), MaxGen = 5; end

    projectRoot = fileparts(fileparts(mfilename('fullpath')));
    netFolder = fullfile(projectRoot, 'networks', folder);

    inpFile = fullfile(netFolder, inpName);
    DFile = fullfile(netFolder, 'D.txt');
    CostFile = fullfile(netFolder, 'Cost.txt');

    assert(isfile(inpFile) && isfile(DFile) && isfile(CostFile), ...
        'createTestEnvironment:MissingFiles', ...
        'Network files not found in %s.', netFolder);

    d = [];
    tempInp = '';

    try

        tempInp = createTempInpFile(inpFile);
        UpdateInpHeadlossFormula(tempInp, 'Hazen-Williams (HW)');

        [d, NP, L, InitialD] = initializeNetwork(tempInp);

        Units = detectNetworkUnits(d);
        Units.DiameterFileUnit = 'in';

        [Din, Cost, D] = loadOptimizationData( ...
            DFile, CostFile, 'in', Units.DiameterUnit);

        validateOptimizationData(D, Cost);

        JunctionIndices = find(strcmpi(d.getNodeType(), 'JUNCTION'));

        FixedPipes = [];
        VariablePipes = 1:NP;

        validateNetworkConsistency( ...
            NP, L, InitialD, Din, D, Cost, FixedPipes, VariablePipes);

        Problem = buildOptimizationProblem( ...
            Din, Cost, D, NP, L, InitialD, ...
            FixedPipes, VariablePipes, Pmin, Vmax, ...
            JunctionIndices, Units);

        Config = buildAlgorithmConfig(NS, MaxGen);
        Config.Seed = 12345;
        Config.Parallel.Enabled = false;

    catch ME
        releaseResources(d, tempInp);
        rethrow(ME);
    end

    Env.d = d;
    Env.TempInp = tempInp;
    Env.Problem = Problem;
    Env.Config = Config;
    Env.Release = @() releaseResources(d, tempInp);

end

function releaseResources(d, tempInp)
    cleanupEpanetObject(d);
    cleanupTempInpFiles(tempInp);
end