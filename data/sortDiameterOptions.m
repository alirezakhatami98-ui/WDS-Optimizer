function [Din, Cost, wasReordered] = sortDiameterOptions(Din, Cost)
% Sorts the (diameter, cost) pairs by ascending diameter so that the
% option index is an ordinal scale (required by the PSO rounding step).

    Din = Din(:);
    Cost = Cost(:);

    if numel(Din) ~= numel(Cost)
        error('sortDiameterOptions:SizeMismatch', ...
            'Diameter data (%d values) and cost data (%d values) must have the same length.', ...
            numel(Din), numel(Cost));
    end

    [Din, order] = sort(Din, 'ascend');
    Cost = Cost(order);

    wasReordered = ~isequal(order(:), (1:numel(order))');

    if any(diff(Cost) < 0)
        warning('sortDiameterOptions:NonMonotoneCost', ...
            ['Cost does not increase with diameter for all options. ', ...
             'Please check Cost.txt.']);
    end

end