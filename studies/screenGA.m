function screenGA()
% Tournament-size screening on Hanoi. Control = scr_ga_tournament (k = 3).

    variants = {'k2', 2; 'k5', 5; 'k7', 7};

    tags = {'scr_ga_tournament'};

    for v = 1:size(variants, 1)

        tag = ['scr_ga_tourn_' variants{v, 1}];

        runValidationStudy( ...
            'Networks', {'hanoi'}, 'Algorithms', {'GA'}, ...
            'NumRuns', 10, 'Tag', tag, ...
            'GA', struct('Selection', 'tournament', ...
                         'TournamentSize', variants{v, 2}));

        tags{end+1} = tag; %#ok<AGROW>

    end

    compareStudies('hanoi', 'GA', tags);

end