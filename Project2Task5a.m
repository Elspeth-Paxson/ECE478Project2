%% Task 5a - AS customer cones |C(i)| from the 2024 relationship graph
% Input : 20241101.as-rel2.txt  (AS1|AS2|relationship|source)
%         -1 : AS1 is the provider of AS2 (p2c)     0 : AS1 and AS2 are peers (p2p)
% Output: Task5a_Cones.csv / .mat  (ASN, GlobalDegree, CustomerDegree, ConeSize)
%
% Put the data file in the same folder as this script (MATLAB's Current Folder),
% or set dataFile to its full path.
%
% Definition: C(i) = {AS i} plus every AS reachable from i by following only
% provider->customer edges. Each AS is counted once however many paths reach it.
%
% Algorithm: build a directed graph with one edge provider -> customer for every -1
% record, then run a breadth-first search (bfsearch) from each AS. BFS marks every AS
% as visited the first time it is reached and never expands it again, so
%   * an AS reachable through several providers is counted once (no double counting)
%   * a cycle simply leads back to an already-visited AS, so the search still ends.
% ASes with no customers have cone size 1 (only themselves) and need no search.
% Requires MATLAB R2016a+ (digraph, bfsearch).
clear; clc;
dataFile = '20241101.as-rel2.txt';

%% 1) Read and clean ----------------------------------------------------------------
fid = fopen(dataFile, 'r');
assert(fid > 0, 'Cannot open "%s". Put it in the Current Folder or use its full path.', dataFile);
C = textscan(fid, '%f %f %f %s', 'Delimiter', '|', 'CommentStyle', '#');
fclose(fid);
a = C{1}; b = C{2}; r = C{3};                 % source column (C{4}) is ignored
nRows = numel(a);

ok = ~isnan(a) & ~isnan(b) & (r == -1 | r == 0);
nBad = nnz(~ok);
selfLink = ok & (a == b);
ok = ok & ~selfLink;                          % self-links excluded

R = unique([a(ok), b(ok), r(ok)], 'rows');    % remove identical records
nDup = nnz(ok) - size(R, 1);

% One consistent relationship per AS pair: flag pairs that appear more than once
pairKey = [min(R(:,1), R(:,2)), max(R(:,1), R(:,2))];
[~, firstIdx] = unique(pairKey, 'rows', 'stable');
nConflict = size(R, 1) - numel(firstIdx);
R = R(firstIdx, :);                           % keep first record of any conflicting pair

%% 2) Build graphs ------------------------------------------------------------------
[ASN, ~, idx] = unique([R(:,1); R(:,2)]);     % node number for every AS
n   = numel(ASN);
u   = idx(1:size(R,1));                       % node of AS1
v   = idx(size(R,1)+1:end);                   % node of AS2
isPC = R(:,3) == -1;

G = digraph(u(isPC), v(isPC), [], n);         % provider -> customer edges only

GlobalDegree   = accumarray([u; v], 1, [n 1]);    % distinct neighbours (any relationship)
CustomerDegree = outdegree(G);                     % direct customers

%% 3) Customer cones ----------------------------------------------------------------
tic;
ConeSize = coneSizes(G);
fprintf('Cones computed in %.1f s\n', toc);

%% 4) Correctness checks ------------------------------------------------------------
% (a) Hand example with a shared customer (E has providers B and C):
%     A->B, A->C, B->D, B->E, C->E, D->F  =>  |C(A)|=6, B=4, C=2, D=2, E=1, F=1
H = digraph([1 1 2 2 3 4], [2 3 4 5 5 6]);
assert(isequal(coneSizes(H)', [6 4 2 2 1 1]), 'Hand example failed');
fprintf('Check (a) shared-customer example: PASS (E counted once, |C(A)| = 6)\n');

% (b) Cycle example A->B->C->A: must terminate, every cone = 3
H = digraph([1 2 3], [2 3 1]);
assert(isequal(coneSizes(H)', [3 3 3]), 'Cycle example failed');
fprintf('Check (b) cycle example: PASS (search terminates, each cone = 3)\n');

% (c) Bounds: 1 + direct customers <= cone <= 1 + sum of the customers' cones
upper = 1 + accumarray(u(isPC), ConeSize(v(isPC)), [n 1]);
assert(all(ConeSize >= 1 + CustomerDegree & ConeSize <= upper), 'Bounds check failed');
fprintf('Check (c) bounds 1 + d_c <= |C(i)| <= 1 + sum of customer cones: PASS\n');

% (d) Does the real p2c graph contain cycles?
fprintf('Check (d) real p2c graph is acyclic (no cycles): %s\n\n', mat2str(isdag(G)));

%% 5) Report ------------------------------------------------------------------------
fprintf('--- Data handling ---\n');
fprintf('Rows read                        : %d\n', nRows);
fprintf('Malformed rows skipped           : %d\n', nBad);
fprintf('Self-links excluded              : %d\n', nnz(selfLink));
fprintf('Duplicate records removed        : %d\n', nDup);
fprintf('Pairs with conflicting relations : %d\n', nConflict);
fprintf('Distinct AS pairs (links)        : %d  (p2c %d, p2p %d)\n', size(R,1), nnz(isPC), nnz(~isPC));
fprintf('ASes in graph                    : %d\n', n);
fprintf('ASes with >= 1 customer          : %d\n', nnz(CustomerDegree > 0));
fprintf('ASes with cone size 1            : %d\n\n', nnz(ConeSize == 1));

T = table(ASN, GlobalDegree, CustomerDegree, ConeSize);
T = sortrows(T, {'ConeSize', 'ASN'}, {'descend', 'ascend'});
fprintf('Top 15 customer cones:\n');
disp(head(T, 15));

writetable(T, 'Task5a_Cones.csv');
save('Task5a_Cones.mat', 'T');
fprintf('Saved Task5a_Cones.csv and Task5a_Cones.mat\n');

%% -----------------------------------------------------------------------------------
function cone = coneSizes(G)
% Size of each node's customer cone: the node itself plus every node reachable
% along directed (provider -> customer) edges. bfsearch visits each node once.
    n    = numnodes(G);
    cone = ones(n, 1);                         % no customers -> cone = {itself}
    for i = find(outdegree(G) > 0)'
        cone(i) = numel(bfsearch(G, i));       % all nodes reachable from i, incl. i
    end
end