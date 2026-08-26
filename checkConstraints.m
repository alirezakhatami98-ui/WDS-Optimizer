function [viol, feas] = checkConstraints(Pj, Vpipes, Pmin, Vmax)

    viol = sum(max(0, Pmin - Pj)) + sum(max(0, Vpipes - Vmax));
    feas = (viol == 0);

end