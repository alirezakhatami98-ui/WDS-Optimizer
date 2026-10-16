function checkDiameterPlausibility(D, DiameterUnit)
% Guards against a wrongly selected diameter-file unit.

    MinMM = 10;
    MaxMM = 6000;

    if strcmp(DiameterUnit, 'in')
        D_mm = D * 25.4;
    else
        D_mm = D;
    end

    if any(D_mm < MinMM) || any(D_mm > MaxMM)
        error('WDS:ImplausibleDiameters', ...
            ['After unit conversion the candidate diameters range from ', ...
             '%.4g to %.4g mm, outside the plausible range %g-%g mm. ', ...
             'Please check the unit selected for the diameter file.'], ...
            min(D_mm), max(D_mm), MinMM, MaxMM);
    end

end