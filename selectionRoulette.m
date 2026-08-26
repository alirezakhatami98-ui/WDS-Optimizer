function idx = selectionRoulette(Fitness, NS)

    prob = Fitness / sum(Fitness);
    cum_prob = cumsum(prob);
    idx = zeros(1, NS);

    for i = 1:NS
        idx(i) = find(rand <= cum_prob, 1, 'first');
    end

end