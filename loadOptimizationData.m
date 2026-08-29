function [Din, Cost, D] = loadOptimizationData(DFilePath, CostFilePath)

    Din = load(DFilePath);
    Cost = load(CostFilePath);
    D = Din * 25.4;

end