function screenGARestart()

    variants = { ...
        'rou_r50',   struct('RestartAfter', 50); ...
        'rou_r100',  struct('RestartAfter', 100); ...
        'tourn_r50', struct('Selection', 'tournament', ...
                            'TournamentSize', 3, 'RestartAfter', 50)};

    tags = {'baseline'};

    for v = 1:size(variants, 1)

        tag = ['scr_ga_' variants{v, 1}];

        runValidationStudy( ...
            'Networks', {'hanoi', '2loops'}, 'Algorithms', {'GA'}, ...
            'NumRuns', 10, 'Tag', tag, 'GA', variants{v, 2});

        tags{end+1} = tag; %#ok<AGROW>

    end

    compareStudies('hanoi',  'GA', tags);
    compareStudies('2loops', 'GA', tags);

end