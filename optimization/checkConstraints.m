function [viol, feas] = checkConstraints( ...
    Pj, Vpipes, Pmin, Vmax, Converged)

    if nargin < 5 || isempty(Converged)
        Converged = true;
    end

    % Finite, deterministic penalty for invalid hydraulic results.
    % It must stay finite: Inf gives zero fitness in calculateFitness,
    % and NaN breaks roulette selection. It is chosen well above the
    % largest violation observed on 2Loops and Hanoi (about 3.5e5).
    InvalidViolation = 1e8;

    % max(0, NaN) is 0 in MATLAB, so non-finite values must be caught
    % explicitly; otherwise they would be reported as feasible.
    if ~Converged || any(~isfinite(Pj)) || any(~isfinite(Vpipes))
        viol = InvalidViolation;
        feas = false;
        return;
    end

    PressureViolation = max(0, (Pmin - Pj) / Pmin);
    VelocityViolation = max(0, (Vpipes - Vmax) / Vmax);

    ViolP = mean(PressureViolation);
    ViolV = mean(VelocityViolation);

    viol = ViolP + ViolV;
    feas = (viol == 0);

end