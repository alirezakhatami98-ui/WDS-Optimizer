function ref = referenceCost(net)
% Best-known costs reported in the literature for the standard problem
% definitions (Hazen-Williams, Pmin = 30 m). Valid only if D.txt, Cost.txt
% and the .inp define exactly the same problem.
    switch lower(net)
        case '2loops'
            ref = 419000;
        case 'hanoi'
            ref = 6081000;
        otherwise
            error('No reference cost for network "%s".', net);
    end
end