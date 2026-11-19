%% Task 3b - Graphs 4a and 4b: distributions of P_i and A_i over origin ASes
% Input : Task3a_PiAi.csv (columns ASN, P_i, A_i), written by Task3a_PiAi.m.
%         Put it in the same folder as this script (the Current Folder).
% Output: Graph4a_Pi.png, Graph4b_Ai.png
%
% Bin choice (logarithmic, base 2):
%  * Both quantities are heavily skewed: most ASes have 1-3 prefixes and a few hundred
%    addresses, but a handful have >10,000 prefixes or >100 million addresses. Linear
%    bins would put almost every AS in the first bar, so bins double in width.
%  * P_i: bins [1], [2-3], [4-7], ... [8192-16383]. Each bin doubles, 1 gets its own bin.
%  * A_i: bins [2^k, 2^(k+1)). Prefix sizes are powers of two (a /n covers 2^(32-n)
%    addresses), so these bins line up with prefix sizes: e.g. [2^8, 2^9) = "one /24's worth".
%  * The y-axis is logarithmic so the small tail bins (1-10 ASes) remain visible
%    next to bins with ~20,000 ASes. Exact counts are printed on every bar.
% Requires MATLAB R2019b+ (XEndPoints).
clear; clc; close all;

T   = readtable('Task3a_PiAi.csv');
P_i = T.P_i;
A_i = T.A_i;
nAS = height(T);
fprintf('Origin ASes: %d\n', nAS);

%% Graph 4a - P_i --------------------------------------------------------------------
kP     = 0:ceil(log2(max(P_i) + 1));           % edges 1, 2, 4, ..., >= max
edgesP = 2 .^ kP;
cntP   = histcounts(P_i, edgesP);
labP   = cell(1, numel(cntP));
for k = 1:numel(cntP)
    lo = edgesP(k); hi = edgesP(k + 1) - 1;
    if lo == hi, labP{k} = sprintf('%d', lo); else, labP{k} = sprintf('%d-%d', lo, hi); end
end

fig1 = figure('Units', 'inches', 'Position', [0.5 0.5 11 6], 'Color', 'w');
ax1  = axes(fig1);
plotLogBars(ax1, cntP, labP, [0.00 0.45 0.74]);
xlabel(ax1, 'Number of distinct advertised IPv4 prefixes, P_i (log_2 bins)');
ylabel(ax1, 'Number of origin ASes (log scale)');
title(ax1, sprintf(['Graph 4a: Distribution of Advertised Prefixes per Origin AS ' ...
      '(N = %d ASes)'], nAS));
exportgraphics(fig1, 'Graph4a_Pi.png', 'Resolution', 300);

%% Graph 4b - A_i --------------------------------------------------------------------
kA     = floor(log2(min(A_i))) : ceil(log2(max(A_i) + 1));
edgesA = 2 .^ kA;
cntA   = histcounts(A_i, edgesA);
labA   = cell(1, numel(cntA));
for k = 1:numel(cntA)
    pfx = 32 - kA(k);                           % prefix length whose size is 2^k
    labA{k} = sprintf('2^{%d} (/%d)', kA(k), pfx);
end

fig2 = figure('Units', 'inches', 'Position', [0.5 0.5 13 6.5], 'Color', 'w');
ax2  = axes(fig2);
plotLogBars(ax2, cntA, labA, [0.85 0.33 0.10], true);   % vertical count labels
ax2.YLim = [0.7, 1e5];                                   % cap 4b y-axis at 10^5
ax2.XTickLabelRotation = 45;
xlabel(ax2, {'Unique advertised IPv4 addresses, A_i  (bin = [2^k, 2^{k+1}); /n = prefix of size 2^k)'});
ylabel(ax2, 'Number of origin ASes (log scale)');
title(ax2, sprintf(['Graph 4b: Distribution of Unique Advertised IPv4 Addresses per Origin AS ' ...
      '(N = %d ASes)'], nAS));
exportgraphics(fig2, 'Graph4b_Ai.png', 'Resolution', 300);

%% Print bin tables for the report ----------------------------------------------------
fprintf('\nP_i bins:\n');  disp(table(labP', cntP', 100*cntP'/nAS, ...
        'VariableNames', {'Bin', 'ASes', 'Percent'}));
fprintf('A_i bins (lower edge 2^k):\n');
disp(table(edgesA(1:end-1)', edgesA(2:end)' - 1, cntA', 100*cntA'/nAS, ...
        'VariableNames', {'From', 'To', 'ASes', 'Percent'}));

%% ------------------------------------------------------------------------------------
function plotLogBars(ax, counts, labels, color, vertLabels)
    if nargin < 5, vertLabels = false; end
    b = bar(ax, 1:numel(counts), counts, 0.85, 'FaceColor', color, 'EdgeColor', 'k');
    ax.YScale = 'log';
    if vertLabels
        ax.YLim = [0.7, max(counts) * 25];      % extra headroom for vertical labels
    else
        ax.YLim = [0.7, max(counts) * 4];
    end
    b.BaseValue = 0.7;                          % bars start at the bottom on a log axis
    ax.XTick      = 1:numel(counts);
    ax.XTickLabel = labels;
    ax.XLim       = [0.4, numel(counts) + 0.6];
    grid(ax, 'on'); ax.YMinorGrid = 'off';
    nz  = find(counts > 0);                     % label every non-empty bar with its count
    lbl = arrayfun(@withCommas, counts(nz), 'UniformOutput', false);
    x   = b.XEndPoints(nz);
    y   = b.YEndPoints(nz);
    if vertLabels                               % vertical text: no collisions between bars
        text(ax, x, y * 1.15, lbl, 'Rotation', 90, 'HorizontalAlignment', 'left', ...
             'VerticalAlignment', 'middle', 'FontSize', 9);
    else
        text(ax, x, y, lbl, 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'bottom', 'FontSize', 9);
    end
end

function s = withCommas(n)
    s = sprintf('%d', n);
    s = regexprep(s, '(\d)(?=(\d{3})+$)', '$1,');   % 15451 -> 15,451
end