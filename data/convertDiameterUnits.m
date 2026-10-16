function D = convertDiameterUnits(Din, FromUnit, ToUnit)
% Units: 'mm' or 'in'.

    FromUnit = lower(strtrim(FromUnit));
    ToUnit = lower(strtrim(ToUnit));

    valid = {'mm', 'in'};

    if ~ismember(FromUnit, valid) || ~ismember(ToUnit, valid)
        error('convertDiameterUnits:InvalidUnit', ...
            'Diameter units must be ''mm'' or ''in''.');
    end

    if strcmp(FromUnit, ToUnit)
        D = Din;                 % no arithmetic: values stay bit-identical
    elseif strcmp(FromUnit, 'in')
        D = Din * 25.4;
    else
        D = Din / 25.4;
    end

end