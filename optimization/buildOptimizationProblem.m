function Problem = buildOptimizationProblem( ...
    Din, Cost, D, NP, L, InitialD, ...
    FixedPipes, VariablePipes, Pmin, Vmax, ...
    JunctionIndices, Units)

    if nargin < 12
        Units = [];
    end

    Problem.Din = Din(:);
    Problem.Cost = Cost(:);
    Problem.D = D(:);

    Problem.NP = NP;
    Problem.L = L(:);
    Problem.InitialD = InitialD(:);

    Problem.FixedPipes = FixedPipes;
    Problem.VariablePipes = VariablePipes(:)';

    Problem.Pmin = Pmin;
    Problem.Vmax = Vmax;

    Problem.JunctionIndices = JunctionIndices;

    % Network unit information (empty when not provided).
    Problem.Units = Units;

end