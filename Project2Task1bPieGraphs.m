%% Graph 1 (Pie Charts) - CAIDA AS Business Classification, 2015 vs 2021
% Layout (top to bottom): 2015 pie, 2021 pie
%         slices by source and type (% of class and % of total)
% Labels are placed as callouts (with leader lines) in a column on each side
% of the pie, spaced so they never overlap.
% Requires MATLAB R2019b or newer (tiledlayout).
clear; clc; close all;

types   = {'Content', 'Enterprise', 'Transit/Access'};
sources = {'CAIDA_class', 'peerDB_class', 'manual_class'};

% Counts: rows = source (CAIDA, peerDB, manual), cols = type (Content, Enterprise, Transit/Access)
c2015 = [ 1346  26471  18512;
           994    192   3209;
             0    783      0 ];

c2021 = [ 2666  19313  36025;
          1667    982  10365;
             0    647      0 ];

srcColors = [0.00 0.45 0.74;    % CAIDA  - blue
             0.85 0.33 0.10;    % peerDB - orange
             0.47 0.67 0.19];   % manual - green

fig = figure('Units', 'inches', 'Position', [0.5 0.5 11 14], 'Color', 'w');
tl  = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, 'Graph 2: Classes by Percentage, 2015 vs 2021', ...
      'FontSize', 16, 'FontWeight', 'bold');

plotPie(nexttile(tl), c2015, '2015 (20150801.as2types.txt)', types, sources, srcColors);
plotPie(nexttile(tl), c2021, '2021 (20210401.as2types.txt)', types, sources, srcColors);

exportgraphics(fig, 'Graph1_pies.png', 'Resolution', 300);

%% ---------------------------------------------------------------------
function plotPie(ax, c, yearLabel, types, sources, srcColors)
    % ---- Tunable layout settings ----
    rotDeg  = -90;    % rotate pie so it starts at 3 o'clock (small slices land on the right)
    labelX  = 1.22;   % x-position of the label columns (pie radius = 1)
    minGap  = 0.30;   % minimum vertical spacing between labels (data units)
    yLimit  = 1.45;   % labels are kept within +/- this height
    fontSz  = 9;

    total    = sum(c(:));
    classTot = sum(c, 2);

    vals = []; lbls = {}; names = {}; cols = [];
    shade = [1.00 0.70 0.45];              % darker -> lighter for Content/Enterprise/Transit
    for s = 1:3
        for t = 1:3
            if c(s, t) == 0, continue; end % pie cannot draw zero slices
            vals(end+1) = c(s, t);                                       %#ok<AGROW>
            lbls{end+1} = sprintf('%.3f%% of class\n%.3f%% of total', ...
                          100*c(s,t)/classTot(s), 100*c(s,t)/total);    %#ok<AGROW>
            names{end+1} = sprintf('%s - %s (%d)', sources{s}, types{t}, c(s,t)); %#ok<AGROW>
            cols(end+1, :) = 1 - shade(t) * (1 - srcColors(s, :));      %#ok<AGROW>
        end
    end

    % Draw pie without its default labels
    h = pie(ax, vals);
    patches = h(1:2:end);
    delete(h(2:2:end));
    hold(ax, 'on');

    % Rotate slices and find each slice's mid-angle on the rim
    R = [cosd(rotDeg) -sind(rotDeg); sind(rotDeg) cosd(rotDeg)];
    n = numel(patches);
    theta = zeros(1, n);
    for k = 1:n
        P = R * [patches(k).XData(:)'; patches(k).YData(:)'];
        patches(k).XData = P(1, :);
        patches(k).YData = P(2, :);
        patches(k).FaceColor = cols(k, :);
        arc = P(:, 2:end);                         % first vertex is the center
        mid = arc(:, ceil(size(arc, 2) / 2));      % middle point of the arc
        theta(k) = atan2(mid(2), mid(1));
    end

    % Place labels: one column per side, spaced to avoid overlap
    side = sign(cos(theta)); side(side == 0) = 1;  % +1 right, -1 left
    yLab = 1.1 * sin(theta);
    for sd = [1 -1]
        idx = find(side == sd);
        [~, order] = sort(yLab(idx), 'descend');
        idx = idx(order);
        for j = 2:numel(idx)                       % push down to keep the gap
            yLab(idx(j)) = min(yLab(idx(j)), yLab(idx(j-1)) - minGap);
        end
        if ~isempty(idx) && yLab(idx(end)) < -yLimit   % shift up if off the bottom
            yLab(idx) = yLab(idx) + (-yLimit - yLab(idx(end)));
        end
    end

    for k = 1:n
        ax0 = cos(theta(k));  ay0 = sin(theta(k));        % point on the rim
        ex  = 1.06 * ax0;     ey  = 1.06 * ay0;           % elbow just outside rim
        tx  = side(k) * labelX;
        plot(ax, [ax0 ex tx - side(k)*0.03], [ay0 ey yLab(k)], '-', ...
             'Color', [0.45 0.45 0.45], 'LineWidth', 0.6, 'HandleVisibility', 'off');
        if side(k) > 0, ha = 'left'; else, ha = 'right'; end
        text(ax, tx, yLab(k), lbls{k}, 'HorizontalAlignment', ha, ...
             'VerticalAlignment', 'middle', 'FontSize', fontSz, 'Interpreter', 'none');
    end

    axis(ax, 'equal');
    axis(ax, [-2.1 2.1 -1.55 1.55]);
    axis(ax, 'off');
    title(ax, sprintf('%s - By Source and Type (Total ASes = %d)', yearLabel, total), ...
          'Interpreter', 'none');
    legend(ax, patches, names, 'Location', 'eastoutside', 'Interpreter', 'none', 'FontSize', 9);
end