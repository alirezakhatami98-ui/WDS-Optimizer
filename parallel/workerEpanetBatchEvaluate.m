function varargout = workerEpanetBatchEvaluate(action, varargin)
% workerEpanetBatchEvaluate
%
% Temporary helper for Step 7F-C1.
% Maintains one EPANET object persistently on each worker.
%
% Actions:
%   initialize
%   evaluate
%   cleanup

persistent d
persistent JunctionIndices
persistent NP
persistent addedPath
persistent tempFolder

switch lower(action)

    case 'initialize'

        inpFile = varargin{1};

        % Reuse existing EPANET object if already initialized.
        if ~isempty(d)
            varargout{1} = true;
            return;
        end

        [tempFolder, name, ext] = fileparts(inpFile);

        addedPath = false;

        if ~contains(path, tempFolder)
            addpath(tempFolder);
            addedPath = true;
        end

        d = epanet([name ext]);

        NP = d.getLinkCount();

        NodeTypes = d.getNodeType();

        JunctionIndices = ...
            find(strcmpi(NodeTypes, 'JUNCTION'));

        varargout{1} = true;


    case 'evaluate'

        Candidates = varargin{1};
        DiameterTable = varargin{2};

        if isempty(d)
            error('workerEpanetBatchEvaluate:NotInitialized', ...
                'EPANET object is not initialized on this worker.');
        end

        NumEvaluations = size(Candidates, 2);

        NumJunctions = numel(JunctionIndices);

        Pj = zeros(NumJunctions, NumEvaluations);
        Vpipes = zeros(NP, NumEvaluations);

        for k = 1:NumEvaluations

            CandidateD = DiameterTable(Candidates(:,k));
            CandidateD = CandidateD(:);

            d.setLinkDiameter(1:NP, CandidateD');

            d.solveCompleteHydraulics();

            P = double(d.getNodePressure());
            V = double(abs(d.getLinkVelocity()));

            Pj(:,k) = P(JunctionIndices);
            Vpipes(:,k) = V;

        end

        varargout{1} = Pj;
        varargout{2} = Vpipes;


    case 'cleanup'

        if ~isempty(d)

            try
                d.unload();
            catch
            end

            d = [];
        end

        JunctionIndices = [];
        NP = [];

        if ~isempty(addedPath)

            if addedPath && ~isempty(tempFolder)

                try
                    rmpath(tempFolder);
                catch
                end

            end

        end

        addedPath = [];
        tempFolder = [];

        varargout{1} = true;


    otherwise

        error('workerEpanetBatchEvaluate:UnknownAction', ...
            'Unknown action: %s', action);

end

end