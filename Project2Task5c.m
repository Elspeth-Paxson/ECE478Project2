%% Task 5c - Graph 6: customer-cone size of the top 100 ASes, and degree vs cone rankings
% Input : Task5a_Cones.csv (ASN, GlobalDegree, CustomerDegree, ConeSize) from Task 5a / 5b.
%         Put it in the Current Folder.
% Output: Graph6_Cones.png, Task5c_Top100.csv (top 100 with all three ranks)
%
% Graph 6: bars = cone size (left axis) in cone-rank order. Markers = each AS's rank by
% global degree and by direct-customer degree, re-ranked 1..100 within these 100 ASes
% (right axis, rank 1 at the top). The dashed line marks 'same rank as cone'.
%
% Ranks: 1 = largest. Ties are broken by the smaller AS number, so every AS gets a
% unique rank. Ranks are over ALL ASes in the 2024 graph, not just the top 100.
clear; clc; close all;
coneFile = 'Task5a_Cones.csv';        % saved by Task 5a / 5b
relFile  = '20241101.as-rel2.txt';    % used only if the CSV is missing

fprintf('Current Folder: %s\n', pwd);
if isfile(coneFile)
    fprintf('Reading %s ...\n', coneFile);
    T = readtable(coneFile);
else
    fprintf('%s not found - computing cones from %s ...\n', coneFile, relFile);
    T = computeCones(relFile);
    writetable(T, coneFile);
end
n = height(T);
fprintf('Loaded %d ASes\n', n);
T.ConeRank = rankDesc(T.ConeSize,       T.ASN);
T.GDRank   = rankDesc(T.GlobalDegree,   T.ASN);
T.CDRank   = rankDesc(T.CustomerDegree, T.ASN);

Top = sortrows(T, 'ConeRank');
Top = Top(1:100, :);

%% Graph 6 ---------------------------------------------------------------------------
fig = figure('Units', 'inches', 'Position', [0.5 0.5 13 6.5], 'Color', 'w', 'Visible', 'on');
ax  = axes(fig);
x   = (1:100)';

yyaxis(ax, 'left');
bar(ax, x, Top.ConeSize, 0.8, 'FaceColor', [0.00 0.45 0.74], 'EdgeColor', 'none');
ylabel(ax, 'Customer-cone size |C(i)| (number of ASes)');
ax.YLim = [0, max(Top.ConeSize) * 1.12];
ax.YAxis(1).Exponent = 0;
ytickformat(ax, '%,d');

GD100 = rerank(Top.GDRank);                 % degree ranks 1..100 within the top 100
CD100 = rerank(Top.CDRank);

yyaxis(ax, 'right');
hold(ax, 'on');
plot(ax, x, GD100, 'o', 'MarkerSize', 5, 'Color', [0.85 0.33 0.10], ...
     'MarkerFaceColor', [0.85 0.33 0.10]);
plot(ax, x, CD100, '^', 'MarkerSize', 5, 'Color', [0.47 0.67 0.19], ...
     'MarkerFaceColor', [0.47 0.67 0.19]);
plot(ax, [1 100], [1 100], 'k--', 'LineWidth', 1);          % same rank as cone
ax.YAxis(2).Direction = 'reverse';                          % rank 1 at the top
ax.YLim  = [0, 101];
ax.YTick = [1 10:10:100];
ylabel(ax, 'Degree rank among these 100 ASes (1 = largest)');
ax.YAxis(2).Color = [0.3 0.3 0.3];

% Label a few ASes discussed in the report
yyaxis(ax, 'left');
note = [3356 1299 174 6939 5511 12956 18116 62467];
for a = note
    k = find(Top.ASN == a, 1);
    if isempty(k), continue; end
    text(ax, k, Top.ConeSize(k) + 1500, sprintf('AS%d', a), 'Rotation', 90, ...
         'FontSize', 8, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
end

xlabel(ax, 'Rank by customer-cone size');
ax.XLim = [0, 101];
grid(ax, 'on');
legend(ax, {'Customer-cone size (left)', 'Global-degree rank (right)', ...
            'Direct-customer-degree rank (right)', 'Same rank as cone'}, ...
       'Location', 'southoutside', 'NumColumns', 4);
title(ax, 'Graph 6: Customer-Cone Size of the Top 100 ASes (2024 relationship graph)');
figure(fig); drawnow;                                      % bring to front
exportgraphics(fig, 'Graph6_Cones.png', 'Resolution', 300);
fprintf('Saved %s\n', fullfile(pwd, 'Graph6_Cones.png'));

%% Ranking comparisons (printed for the write-up) ------------------------------------
writetable(Top(:, {'ConeRank', 'ASN', 'ConeSize', 'GlobalDegree', 'GDRank', ...
                   'CustomerDegree', 'CDRank'}), 'Task5c_Top100.csv');

fprintf('Cone size: rank 1 = %d, rank 50 = %d, rank 100 = %d\n\n', ...
        Top.ConeSize(1), Top.ConeSize(50), Top.ConeSize(100));

% Agreement between rankings among the top-100-cone ASes (Spearman = Pearson on ranks)
rc  = rerank(Top.ConeRank);
rho_gd = corrcoef(rc, rerank(Top.GDRank));
rho_cd = corrcoef(rc, rerank(Top.CDRank));
fprintf('Spearman correlation (top 100 by cone): cone vs global degree = %.3f, cone vs customer degree = %.3f\n', ...
        rho_gd(1,2), rho_cd(1,2));
fprintf('Top-100 cone ASes also in top 100 by global degree   : %d\n', nnz(Top.GDRank <= 100));
fprintf('Top-100 cone ASes also in top 100 by customer degree : %d\n\n', nnz(Top.CDRank <= 100));

cols = {'ASN', 'GlobalDegree', 'GDRank', 'CustomerDegree', 'CDRank', 'ConeSize', 'ConeRank'};
fprintf('Top 15 by GLOBAL degree, with cone rank:\n');
disp(head(sortrows(T(:, cols), 'GDRank'), 15));
fprintf('Top 15 by CUSTOMER degree, with cone rank:\n');
disp(head(sortrows(T(:, cols), 'CDRank'), 15));
fprintf('Top-100 cone ASes with the LOWEST global-degree rank:\n');
disp(head(sortrows(Top(:, cols), 'GDRank', 'descend'), 10));

%% -----------------------------------------------------------------------------------
function r = rankDesc(x, asn)
% Rank 1 = largest x; ties broken by smaller ASN.
    [~, ord] = sortrows([-x, asn]);
    r = zeros(numel(x), 1);
    r(ord) = 1:numel(x);
end

function r = rerank(x)
% Re-rank values 1..m (used to compare rankings within the top 100).
    [~, ord] = sort(x);
    r = zeros(numel(x), 1);
    r(ord) = 1:numel(x);
end

function T = computeCones(relFile)
% Same method as Task 5a: p2c digraph + BFS from every AS with customers.
    fid = fopen(relFile, 'r');
    assert(fid > 0, 'Cannot open "%s" either. Put it or Task5a_Cones.csv in %s', relFile, pwd);
    C = textscan(fid, '%f %f %f %s', 'Delimiter', '|', 'CommentStyle', '#');
    fclose(fid);
    a = C{1}; b = C{2}; r = C{3};
    ok = ~isnan(a) & ~isnan(b) & (r == -1 | r == 0) & a ~= b;
    R = unique([a(ok), b(ok), r(ok)], 'rows');
    [~, first] = unique([min(R(:,1), R(:,2)), max(R(:,1), R(:,2))], 'rows', 'stable');
    R = R(first, :);
    [ASN, ~, idx] = unique([R(:,1); R(:,2)]);
    n = numel(ASN);
    u = idx(1:size(R,1));  v = idx(size(R,1)+1:end);
    isPC = R(:,3) == -1;
    G = digraph(u(isPC), v(isPC), [], n);
    GlobalDegree   = accumarray([u; v], 1, [n 1]);
    CustomerDegree = outdegree(G);
    ConeSize = ones(n, 1);
    for i = find(CustomerDegree > 0)'
        ConeSize(i) = numel(bfsearch(G, i));
    end
    T = table(ASN, GlobalDegree, CustomerDegree, ConeSize);
end