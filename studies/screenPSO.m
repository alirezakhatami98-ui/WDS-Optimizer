function screenPSO()
% Parameter-only screening of PSO on Hanoi. The control is the baseline study.
% Adjust the variants after looking at the default PSO parameters.

    variants = { ...
        'w09',        struct('w', 0.9); ...
        'c2low',      struct('c1', 2.0, 'c2', 0.5); ...
        'w09_c2low',  struct('w', 0.9, 'c1', 2.0, 'c2', 0.5); ...
        'c1c2_eq1',   struct('c1', 1.0, 'c2', 1.0)};

    tags = {'baseline'};

    for v = 1:size(variants, 1)

        tag = ['scr_pso_' variants{v, 1}];

        runValidationStudy( ...
            'Networks', {'hanoi'}, 'Algorithms', {'PSO'}, ...
            'NumRuns', 10, 'Tag', tag, 'PSO', variants{v, 2});

        tags{end+1} = tag; %#ok<AGROW>

    end

    compareStudies('hanoi', 'PSO', tags);

end