%% Graph 1 (Bar Graphs) - CAIDA AS Business Classification, 2015 vs 2021
% Layout (top to bottom): 2015 bar, 2021 bar
% Requires MATLAB R2019b or newer (tiledlayout, XEndPoints).
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
totColor  = [0.45 0.45 0.45];   % Total  - gray

fig = figure('Units', 'inches', 'Position', [0.5 0.5 11 9], 'Color', 'w');
tl  = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, 'Graph 1a: AS counts by Source and Class, 2015 vs 2021', ...
      'FontSize', 16, 'FontWeight', 'bold');

plotBars(nexttile(tl), c2015, '2015 (20150801.as2types.txt)', types, sources, srcColors, totColor);
plotBars(nexttile(tl), c2021, '2021 (20210401.as2types.txt)', types, sources, srcColors, totColor);

exportgraphics(fig, 'Graph1_bars.png', 'Resolution', 300);

%% ---------------------------------------------------------------------
function plotBars(ax, c, yearLabel, types, sources, srcColors, totColor)
    Y = [c', sum(c, 1)';                  % 3 types x 4 series (3 sources + Total)
         sum(c, 2)', sum(c(:))];          % far-right group: all types combined
    b = bar(ax, Y, 'grouped');
    for k = 1:3
        b(k).FaceColor = srcColors(k, :);
    end
    b(4).FaceColor = totColor;

    % Count labels on top of every bar
    for k = 1:numel(b)
        text(ax, b(k).XEndPoints, b(k).YEndPoints, compose('%d', b(k).YData), ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
             'FontSize', 9);
    end

    ax.XTickLabel = [types, {'All Types Combined'}];
    xline(ax, 3.5, '--k', 'HandleVisibility', 'off');   % separate combined group
    ax.YLim = [0, max(Y(:)) * 1.15];      % headroom for labels
    ax.YAxis.Exponent = 0;
    ytickformat(ax, '%,d');
    ylabel(ax, 'Number of ASes');
    grid(ax, 'on');
    title(ax, sprintf('%s - Counts by Type and Source (Total ASes = %d)', ...
          yearLabel, sum(c(:))), 'Interpreter', 'none');
    legend(ax, [sources, {'Total'}], 'Location', 'northwest', 'Interpreter', 'none');
end