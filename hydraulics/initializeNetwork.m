function [d, NP, L, InitialD] = initializeNetwork(inpFilePath)

    d = epanet(inpFilePath);

    NP = d.getLinkPipeCount();

    L = zeros(NP, 1);
    InitialD = zeros(NP, 1);

    for i = 1:NP
        L(i) = d.getLinkLength(i);
        InitialD(i) = d.getLinkDiameter(i);
    end

end