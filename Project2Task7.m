%% Task 7 - Peering core and candidate Tier-1 ASes (greedy largest clique)
% Inputs (Current Folder): 20241101.as-rel2.txt, 20251001.as-org2info1.txt
% Output: Task7_Clique.csv (all clique members), Task7_Table_First10.csv
%
% Graph: undirected, every link counts (p2c -1 or p2p 0), self-links excluded,
%        duplicate records removed. Degree = number of distinct neighbours.
% Ranking: descending global degree; ties broken by smaller AS number.
%
% Greedy heuristic (as specified):
%   S = {AS1}. Go down the ranked list; add an AS if it is linked to EVERY AS already
%   in S.
%   * Strict version: stop at the first AS that is not linked to all of S.
%   * Extended version (the note in the assignment): skip an AS that does not fit and
%     keep checking the next ones, considering the top 50 ASes.
clear; clc;
format long g          % show plain whole numbers in the Command Window
relFile = '20241101.as-rel2.txt';
orgFile = '20251001.as-org2info1.txt';
topK    = 50;          % how far down the ranked list to look (extended version)
nShow   = 10;          % rows for the report table

%% 1) Read relationships and build the undirected graph ------------------------------
fid = fopen(relFile, 'r');
assert(fid > 0, 'Cannot open "%s". Put it in the Current Folder.', relFile);
C = textscan(fid, '%f %f %f %s', 'Delimiter', '|', 'CommentStyle', '#');
fclose(fid);
a = C{1}; b = C{2}; r = C{3};
ok = ~isnan(a) & ~isnan(b) & (r == -1 | r == 0) & a ~= b;     % drop malformed / self-links
P  = unique([min(a(ok), b(ok)), max(a(ok), b(ok))], 'rows');   % one row per AS pair

[ASN, ~, idx] = unique(P(:));                  % node number for every AS
n = numel(ASN);
u = idx(1:size(P,1));  v = idx(size(P,1)+1:end);
A = sparse([u; v], [v; u], true, n, n);        % adjacency matrix (symmetric)
deg = full(sum(A, 2));                         % global degree

[~, order] = sortrows([-deg, ASN]);            % ranked list R (node numbers)
degRank = zeros(n, 1);  degRank(order) = 1:n;
fprintf('ASes: %d, links: %d\n\n', n, size(P,1));

%% 2) Strict greedy: stop at the first AS that does not fit --------------------------
S = order(1);
for k = 2:n
    c = order(k);
    linked = full(A(c, S));                                     % links to current members
    if all(linked)
        S(end+1) = c;                                           %#ok<AGROW>
    else
        missing = ASN(S(~linked));
        fprintf('STRICT: stops at rank %d (AS%d), not linked to AS%s\n', ...
                k, ASN(c), strjoin(string(missing), ', AS'));
        break
    end
end
Sstrict = S;
fprintf('STRICT clique size: %d  (AS%s)\n\n', numel(Sstrict), ...
        strjoin(string(ASN(Sstrict)), ', AS'));

%% 3) Extended greedy: skip ASes that do not fit, consider the top 50 ----------------
S = order(1);
skipped = [];
for k = 2:topK
    c = order(k);
    linked = full(A(c, S));
    if all(linked)
        S(end+1) = c;                                           %#ok<AGROW>
    else
        skipped(end+1) = c;                                     %#ok<AGROW>
        fprintf('  skip rank %2d AS%-7d (not linked to %d clique member(s): AS%s)\n', ...
                k, ASN(c), nnz(~linked), strjoin(string(ASN(S(~linked))), ', AS'));
    end
end
fprintf('\nEXTENDED clique size (top %d considered): %d, skipped: %d\n', ...
        topK, numel(S), numel(skipped));

% Verify: every pair of members is linked
B = full(A(S, S));
assert(all(B(~eye(numel(S)))), 'Clique check failed');
fprintf('Check: all %d pairs of members are directly linked - PASS\n\n', nchoosek(numel(S), 2));

%% 4) Organization names -------------------------------------------------------------
L  = splitlines(string(fileread(orgFile)));
L  = L(strlength(L) > 0 & ~startsWith(L, "#"));
nf = count(L, "|") + 1;
autL = L(nf == 6);  orgL = L(nf == 5);
autASN = str2double(extractBefore(autL, "|"));
orgID  = extractBefore(orgL, "|");

Organization = strings(numel(S), 1);
for k = 1:numel(S)
    Organization(k) = "(not available)";
    j = find(autASN == ASN(S(k)), 1);
    if isempty(j), continue; end
    f = split(autL(j), "|");
    m = find(orgID == f(4), 1);
    if ~isempty(m)
        g = split(orgL(m), "|");
        if strlength(g(3)) > 0, Organization(k) = g(3); end
    end
end

%% 5) Tables -------------------------------------------------------------------------
Order         = int64((1:numel(S))');      % int64 so tables show whole numbers,
ASNumber      = int64(ASN(S));             % not scientific notation (e.g. 1.9952e+05)
IncidentLinks = int64(deg(S));
DegreeRank    = int64(degRank(S));
Clique = table(Order, ASNumber, Organization, IncidentLinks, DegreeRank);

fprintf('First %d ASes added to the clique:\n', nShow);
disp(Clique(1:min(nShow, height(Clique)), :));

writetable(Clique, 'Task7_Clique.csv');
writetable(Clique(1:min(nShow, height(Clique)), :), 'Task7_Table_First10.csv');
fprintf('Saved Task7_Clique.csv and Task7_Table_First10.csv\n');