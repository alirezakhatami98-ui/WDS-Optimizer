function screenPSORestart()

    variants = {'r20', 20; 'r40', 40};

    tags = {'baseline'};

    for v = 1:size(variants, 1)

        tag = ['scr_pso_restart_' variants{v, 1}];

        runValidationStudy( ...
            'Networks', {'hanoi', '2loops'}, 'Algorithms', {'PSO'}, ...
            'NumRuns', 10, 'Tag', tag, ...
            'PSO', struct('RestartAfter', variants{v, 2}));

        tags{end+1} = tag; %#ok<AGROW>

    end

    compareStudies('hanoi',  'PSO', tags);
    compareStudies('2loops', 'PSO', tags);

end