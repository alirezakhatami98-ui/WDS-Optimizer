function [viol, feas] = checkConstraints(Pj, Vpipes, Pmin, Vmax)

    PressureViolation = max(0, (Pmin - Pj) / Pmin);
    VelocityViolation = max(0, (Vpipes - Vmax) / Vmax);

    ViolP = mean(PressureViolation);
    ViolV = mean(VelocityViolation);

    viol = ViolP + ViolV;
    feas = (viol == 0);

end