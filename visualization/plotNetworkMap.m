function plotNetworkMap(ax, Network, Hydraulics, Diameters, Problem, Options)
%PLOTNETWORKMAP Render the water network with coloring by the chosen mode.
%
%   Options fields (all optional):
%     Mode           - 'preview' | 'velocity' | 'pressure' | 'diameter' | 'violations'
%     ShowNodeLabels - true/false, default false
%     ShowLinkLabels - true/false, default false
%     ShowViolations - true/false, default true

    if nargin < 6 || isempty(Options)
        Options = struct();
    end

    Mode           = getOpt(Options, 'Mode', 'velocity');
    ShowNodeLabels = getOpt(Options, 'ShowNodeLabels', false);
    ShowLinkLabels = getOpt(Options, 'ShowLinkLabels', false);
    ShowViol = getOpt(Options, 'ShowViolations', true);

    if isempty(Network) || ~isfield(Network, 'NodeIDs') || ...
            isempty(Network.NodeIDs)
        cla(ax, 'reset');
        title(ax, 'Network Map: no topology available');
        return;
    end

    if nargin < 4 || isempty(Diameters) || numel(Diameters) ~= Problem.NP
        Diameters = Problem.InitialD(:)';
    end
    Diameters = Diameters(:)';

    cla(ax, 'reset');
    hold(ax, 'on');

    nNodes = numel(Network.NodeIDs);
    nLinks = numel(Network.LinkIDs);
    X = Network.NodeCoordinates(:, 1);
    Y = Network.NodeCoordinates(:, 2);
    NP = Problem.NP;

    % ---- Classify links ----
    isPipeVec = false(nLinks, 1);
    hasLinkTypes = isfield(Network, 'LinkTypes') && ...
        numel(Network.LinkTypes) == nLinks;
    if hasLinkTypes
        for k = 1:nLinks
            t = upper(char(Network.LinkTypes{k}));
            isPipeVec(k) = strcmp(t, 'PIPE') || strcmp(t, 'CVPIPE');
        end
    else
        isPipeVec(1:min(NP, nLinks)) = true;
    end
    pipeLinkIndices = find(isPipeVec);

    % Map from link index -> pipe index (1..NP), 0 for non-pipes
    pipeIdxForLink = zeros(nLinks, 1);
    for i = 1:numel(pipeLinkIndices)
        pipeIdxForLink(pipeLinkIndices(i)) = i;
    end

    isPreview = strcmpi(Mode, 'preview');

    % ---- Resolve color scheme ----
    [PipeFaceColors, PipeWidths, PipeCLims, PipeLabel, PipeCmap, ...
        NodeFaceColors, NodeCLims, NodeLabel, NodeCmap] = ...
        buildColorContext(Mode, Hydraulics, Diameters, Problem, ...
                          nNodes, NP, Network);

    % ---- Draw links ----
    for k = 1:nLinks
        a = Network.LinkNodes(k, 1);
        b = Network.LinkNodes(k, 2);

        if isPipeVec(k)
            pi = pipeIdxForLink(k);
            c = PipeFaceColors(pi, :);
            w = PipeWidths(pi);
        else
            c = [0.45 0.45 0.45];
            w = 2.0;
        end

        plot(ax, [X(a) X(b)], [Y(a) Y(b)], '-', ...
            'Color', c, 'LineWidth', w);
    end

    % ---- Fixed-pipe overlay ----
    if isPreview
        fixedColor = [0.95 0.55 0.10];
        fixedWidth = 2.5;
    else
        fixedColor = [0.55 0.55 0.55];
        fixedWidth = 1.1;
    end

    if ~isempty(Problem.FixedPipes)
        for i = 1:numel(Problem.FixedPipes)
            pi = Problem.FixedPipes(i);
            if pi < 1 || pi > numel(pipeLinkIndices), continue; end
            k = pipeLinkIndices(pi);
            a = Network.LinkNodes(k, 1);
            b = Network.LinkNodes(k, 2);
            plot(ax, [X(a) X(b)], [Y(a) Y(b)], '--', ...
                'Color', fixedColor, 'LineWidth', fixedWidth);
        end
    end

    % ---- Violation overlays ----
    if ShowViol && ~isPreview
        for i = 1:numel(pipeLinkIndices)
            if Hydraulics.PipeVelocities(i) > Problem.Vmax
                k = pipeLinkIndices(i);
                a = Network.LinkNodes(k, 1);
                b = Network.LinkNodes(k, 2);
                plot(ax, [X(a) X(b)], [Y(a) Y(b)], ':', ...
                    'Color', [0.85 0.10 0.10], 'LineWidth', 2.0);
            end
        end
    end

    % ---- Draw nodes ----
    Reverse = zeros(nNodes, 1);
    if isfield(Problem, 'JunctionIndices')
        Reverse(Problem.JunctionIndices) = ...
            1:numel(Problem.JunctionIndices);
    end

    for k = 1:nNodes
        t = upper(char(Network.NodeTypes{k}));
        switch t
            case 'RESERVOIR', marker = 's'; sz = 110;
            case 'TANK',      marker = 'p'; sz = 130;
            otherwise,        marker = 'o'; sz = 55;
        end

        fc = NodeFaceColors(k, :);
        ec = [0.20 0.20 0.20];
        lw = 1.0;

        if ShowViol && ~isPreview && Reverse(k) > 0 && ...
                Hydraulics.NodePressures(Reverse(k)) < Problem.Pmin
            ec = [0.85 0.10 0.10];
            lw = 2.5;
        end

        scatter(ax, X(k), Y(k), sz, fc, marker, 'filled', ...
            'MarkerEdgeColor', ec, 'LineWidth', lw);
    end

    % ---- Labels ----
    if ShowNodeLabels
        for k = 1:nNodes
            text(ax, X(k), Y(k), char(Network.NodeIDs{k}), ...
                'FontSize', 7, 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom');
        end
    end

    if ShowLinkLabels
        for k = 1:nLinks
            a = Network.LinkNodes(k, 1);
            b = Network.LinkNodes(k, 2);
            xm = (X(a) + X(b)) / 2;
            ym = (Y(a) + Y(b)) / 2;
            text(ax, xm, ym, char(Network.LinkIDs{k}), ...
                'FontSize', 6, 'Color', [0.35 0.35 0.35]);
        end
    end

    % ---- Legend ----
    h_junc  = scatter(ax, nan, nan, 55,  [0.90 0.90 0.90], 'o', 'filled', ...
        'MarkerEdgeColor', [0.2 0.2 0.2], 'LineWidth', 1);
    h_res   = scatter(ax, nan, nan, 110, [0.20 0.70 0.30], 's', 'filled', ...
        'MarkerEdgeColor', [0.2 0.2 0.2], 'LineWidth', 1);
    h_tank  = scatter(ax, nan, nan, 130, [0.20 0.70 0.70], 'p', 'filled', ...
        'MarkerEdgeColor', [0.2 0.2 0.2], 'LineWidth', 1);
    h_fixed = plot(ax, nan, nan, '--', 'Color', fixedColor, ...
        'LineWidth', fixedWidth);

    if isPreview
        legend(ax, [h_junc, h_res, h_tank, h_fixed], ...
            {'Junction', 'Reservoir', 'Tank', 'Fixed pipe'}, ...
            'Location', 'southoutside', 'Orientation', 'horizontal');
    else
        h_viol = plot(ax, nan, nan, ':', ...
            'Color', [0.85 0.10 0.10], 'LineWidth', 2.0);
        legend(ax, [h_junc, h_res, h_tank, h_fixed, h_viol], ...
            {'Junction', 'Reservoir', 'Tank', 'Fixed pipe', 'Violation'}, ...
            'Location', 'southoutside', 'Orientation', 'horizontal');
    end

    hold(ax, 'off');

    % ---- Axes cosmetics ----
    axis(ax, 'equal');
    axis(ax, 'off');

    ModeNames = struct( ...
        'velocity',   'Velocity', ...
        'pressure',   'Pressure', ...
        'diameter',   'Diameter', ...
        'violations', 'Violations', ...
        'preview',    'Preview — click a pipe to toggle fixed status');
    if isfield(ModeNames, Mode)
        title(ax, sprintf('Network Map (%s)', ModeNames.(Mode)));
    end

    % ---- Colorbar ----
    if ~isempty(PipeCLims) && ~isempty(PipeCmap)
        colormap(ax, PipeCmap);
        setColorLimits(ax, PipeCLims);
        cb = colorbar(ax, 'eastoutside');
        ylabel(cb, PipeLabel);
    elseif ~isempty(NodeCLims) && ~isempty(NodeCmap)
        colormap(ax, NodeCmap);
        setColorLimits(ax, NodeCLims);
        cb = colorbar(ax, 'eastoutside');
        ylabel(cb, NodeLabel);
    end

    % ---- Enable click-through in preview mode ----
    if isPreview
        children = ax.Children;
        for i = 1:numel(children)
            try
                children(i).PickableParts = 'none';
            catch
            end
        end
    end
end

% ------------------------------------------------------------------------
%  Helpers
% ------------------------------------------------------------------------

function v = getOpt(s, f, d)
    if isfield(s, f) && ~isempty(s.(f))
        v = s.(f);
    else
        v = d;
    end
end

function setColorLimits(ax, lims)
    try
        clim(ax, lims);
    catch
        caxis(ax, lims);
    end
end

function [PFc, PW, PCl, PLb, PCm, NFc, NCl, NLb, NCm] = ...
    buildColorContext(Mode, H, D, P, nNodes, NP, Network)

    PFc = repmat([0.7 0.7 0.7], max(NP, 1), 1);
    PW  = 1.5 * ones(max(NP, 1), 1);
    PCl = []; PCm = []; PLb = '';
    NFc = repmat([0.9 0.9 0.9], nNodes, 1);
    NCl = []; NCm = []; NLb = '';

    U = P.Units;
    if isempty(U)
        U.VelocityUnit = 'm/s';
        U.PressureUnit = 'm';
        U.DiameterUnit = 'mm';
    end

    if ~isempty(D)
        dmin = min(D); dmax = max(D);
        if dmax > dmin
            PW = 1.0 + 4.0 * (D(:) - dmin) / (dmax - dmin);
        else
            PW = 2.0 * ones(NP, 1);
        end
    end

    Reverse = zeros(nNodes, 1);
    if isfield(P, 'JunctionIndices')
        Reverse(P.JunctionIndices) = 1:numel(P.JunctionIndices);
    end

    switch lower(Mode)
        case 'preview'
            PFc = repmat([0.62 0.62 0.62], max(NP, 1), 1);
            NFc = repmat([0.92 0.92 0.92], nNodes, 1);
            isRes = strcmpi(Network.NodeTypes, 'RESERVOIR');
            isTk  = strcmpi(Network.NodeTypes, 'TANK');
            NFc(isRes, :) = repmat([0.2 0.7 0.3], sum(isRes), 1);
            NFc(isTk,  :) = repmat([0.2 0.7 0.7], sum(isTk),  1);

        case 'velocity'
            V = H.PipeVelocities(:);
            if isempty(V), return; end
            vmax = P.Vmax;
            hi = max(1.15 * vmax, 1.05 * max(V));
            PCl = [0, hi];
            PCm = cmapVelocity(256);
            PLb = sprintf('Velocity (%s)', U.VelocityUnit);
            PFc = valueToColor(V, PCl, PCm);

        case 'pressure'
            Vp = H.NodePressures(:);
            if isempty(Vp), return; end
            lo = min(0.9 * P.Pmin, min(Vp));
            hi = max(1.1 * max(Vp), 1.1 * P.Pmin);
            NCl = [lo, hi];
            NCm = cmapPressure(256);
            NLb = sprintf('Pressure (%s)', U.PressureUnit);

            for k = 1:nNodes
                li = Reverse(k);
                if li == 0
                    NFc(k, :) = [0.7 0.7 0.7];
                else
                    NFc(k, :) = valueToColor(Vp(li), NCl, NCm);
                end
            end
            isRes = strcmpi(Network.NodeTypes, 'RESERVOIR');
            isTk  = strcmpi(Network.NodeTypes, 'TANK');
            NFc(isRes, :) = repmat([0.2 0.7 0.3], sum(isRes), 1);
            NFc(isTk,  :) = repmat([0.2 0.7 0.7], sum(isTk),  1);

        case 'diameter'
            if isempty(D), return; end
            PCl = [min(D), max(D)];
            if PCl(2) <= PCl(1), PCl(2) = PCl(1) + 1; end
            PCm = cmapDiameter(256);
            PLb = sprintf('Diameter (%s)', U.DiameterUnit);
            PFc = valueToColor(D(:), PCl, PCm);

        case 'violations'
            PFc = repmat([0.75 0.75 0.75], max(NP, 1), 1);
            NFc = repmat([0.92 0.92 0.92], nNodes, 1);
            isRes = strcmpi(Network.NodeTypes, 'RESERVOIR');
            isTk  = strcmpi(Network.NodeTypes, 'TANK');
            NFc(isRes, :) = repmat([0.2 0.7 0.3], sum(isRes), 1);
            NFc(isTk,  :) = repmat([0.2 0.7 0.7], sum(isTk),  1);
    end
end

function c = valueToColor(values, lims, cmap)
    n = size(cmap, 1);
    values = values(:);
    span = lims(2) - lims(1);
    if span <= 0, span = 1; end
    frac = (values - lims(1)) / span;
    frac = max(0, min(1, frac));
    idx = round(1 + frac * (n - 1));
    c = cmap(idx, :);
end

function m = cmapVelocity(n)
    anchors = [ ...
        0.00, 0.25, 0.70, 0.30;
        0.50, 0.90, 0.90, 0.20;
        0.85, 0.95, 0.55, 0.10;
        1.00, 0.85, 0.10, 0.10];
    m = interpColormap(anchors, n);
end

function m = cmapPressure(n)
    anchors = [ ...
        0.00, 0.85, 0.10, 0.10;
        0.25, 0.95, 0.55, 0.10;
        0.50, 0.90, 0.90, 0.20;
        0.75, 0.30, 0.70, 0.30;
        1.00, 0.15, 0.40, 0.80];
    m = interpColormap(anchors, n);
end

function m = cmapDiameter(n)
    anchors = [ ...
        0.00, 0.15, 0.30, 0.70;
        0.33, 0.20, 0.70, 0.40;
        0.66, 0.90, 0.85, 0.20;
        1.00, 0.85, 0.20, 0.10];
    m = interpColormap(anchors, n);
end

function m = interpColormap(anchors, n)
    xq = linspace(0, 1, n)';
    m = interp1(anchors(:,1), anchors(:,2:4), xq);
end