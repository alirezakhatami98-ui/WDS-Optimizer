function Fitness = calculateFitness(cost, viol)

    Fitness = 1 ./ (cost + 2e6 * (viol .^ 2) + 1e-6);

end