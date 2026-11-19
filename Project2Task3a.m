%% Task 3a - Advertised IPv4 prefixes (P_i) and unique IPv4 addresses (A_i) per origin AS
% Input : routeviews-rv2-20251110-1200.pfx2as.txt  (prefix <TAB> length <TAB> origin)
% Output: Task3a_PiAi.csv / Task3a_PiAi.mat  (ASN, P_i, A_i) for Tasks 3b and 3c
%
% Put the data file in the SAME folder as this script and make that folder MATLAB's
% Current Folder - or set dataFile below to the file's full path.
%
% Data-handling choices:
%  * Lines starting with '#' and blank lines are ignored. A row is malformed if the IP is
%    not a.b.c.d with octets 0-255, the length is not an integer 0-32, or the origin field
%    is empty/non-numeric; malformed rows are counted and skipped.
%  * Prefixes are normalised to their network address (host bits cleared).
%  * Origin field: '_' separates multiple origin ASes (MOAS) and ',' separates members of
%    an AS-set. Every AS listed is treated as an origin of that prefix (per-AS results),
%    and a repeated AS inside one origin field is counted once.
%  * Duplicates: identical (ASN, prefix, length) records are counted once, so P_i counts
%    DISTINCT prefixes.
%  * A_i = size of the union of the AS's prefixes: nested/overlapping prefixes are never
%    double-counted (a /24 inside an advertised /16 adds nothing).
%  * The global union counts each prefix once regardless of how many origins it has.
% Requires MATLAB R2016b+ (contains, string functions).

clear; clc;
dataFile = 'routeviews-rv2-20251110-1200.pfx2as.txt';

%% 1) Read the file -------------------------------------------------------------------
fid = fopen(dataFile, 'r');
assert(fid > 0, 'Cannot open "%s". Put it in the Current Folder or use its full path.', dataFile);
C = textscan(fid, '%s %s %s', 'Delimiter', '\t', 'CommentStyle', '#', 'Whitespace', '');
fclose(fid);
ipStr  = C{1};
lenStr = C{2};
orgStr = strtrim(C{3});
nRows  = numel(ipStr);
fprintf('Data rows read: %d\n', nRows);

%% 2) Parse IP, prefix length, validity ------------------------------------------------
v = sscanf(strjoin(ipStr', ' '), '%d.%d.%d.%d');
if numel(v) == 4 * nRows
    oct = reshape(v, 4, nRows)';
else                                            % slow fallback if any IP is malformed
    oct = NaN(nRows, 4);
    for k = 1:nRows
        t = sscanf(ipStr{k}, '%d.%d.%d.%d');
        if numel(t) == 4, oct(k, :) = t'; end
    end
end
len = str2double(lenStr);

valid = all(oct >= 0 & oct <= 255, 2) & len >= 0 & len <= 32 & len == floor(len) ...
        & ~cellfun(@isempty, orgStr);

ipNum    = oct * [2^24; 2^16; 2^8; 1];          % IPv4 as a number (exact in double)
blkSize  = 2 .^ (32 - len);
netStart = floor(ipNum ./ blkSize) .* blkSize;  % clear host bits
hostBits = valid & (netStart ~= ipNum);

%% 3) Expand origins into (ASN, row) pairs ---------------------------------------------
isMOAS  = contains(orgStr, '_');
isASset = contains(orgStr, ',');

simpleRows = find(valid & ~isMOAS & ~isASset);
asSimple   = str2double(orgStr(simpleRows));
badOrigin  = simpleRows(isnan(asSimple));
valid(badOrigin) = false;
simpleRows = simpleRows(~isnan(asSimple));
asSimple   = asSimple(~isnan(asSimple));

multiRows = find(valid & (isMOAS | isASset));
cAS  = cell(numel(multiRows), 1);
cRow = cell(numel(multiRows), 1);
for k = 1:numel(multiRows)
    a = unique(str2double(regexp(orgStr{multiRows(k)}, '[_,]', 'split')));
    a = a(~isnan(a));
    cAS{k}  = a(:);
    cRow{k} = repmat(multiRows(k), numel(a), 1);
end
pairAS  = [asSimple;   vertcat(cAS{:})];
pairRow = [simpleRows; vertcat(cRow{:})];

%% 4) Deduplicate (ASN, prefix, length) and compute P_i and A_i ------------------------
raw = [pairAS, netStart(pairRow), len(pairRow)];
PL  = unique(raw, 'rows');        % sorted by ASN, then start, then length (big block first)
nDupPairs = size(raw, 1) - size(PL, 1);

added       = unionAdded(PL(:, 1), PL(:, 2), PL(:, 3));
[ASN, ~, g] = unique(PL(:, 1));
P_i = accumarray(g, 1);
A_i = accumarray(g, added);

%% 5) Global union (each prefix once, regardless of origins) ---------------------------
G        = unique([netStart(valid), len(valid)], 'rows');
globalA  = sum(unionAdded(ones(size(G, 1), 1), G(:, 1), G(:, 2)));
sumSizes = sum(2 .^ (32 - G(:, 2)));

%% 6) Correctness checks for the prefix union ------------------------------------------
% (a) Hand-made cases with known answers
ip = @(a, b, c, d) a*2^24 + b*2^16 + c*2^8 + d;
t1 = sum(unionAdded([1; 1], [ip(10,0,0,0); ip(10,0,5,0)], [16; 24]));   % /24 inside /16
t2 = sum(unionAdded([1; 1], [ip(10,0,0,0); ip(10,0,1,0)], [24; 24]));   % adjacent /24s
t3 = sum(unionAdded([1; 1], [ip(10,0,0,0); ip(10,0,0,0)], [24; 25]));   % /25 inside /24
assert(t1 == 65536 && t2 == 512 && t3 == 256, 'Hand-made union test failed');
fprintf('Check (a) hand-made cases: PASS  (/16+/24 inside = %d, two adjacent /24 = %d, /24+/25 = %d)\n', t1, t2, t3);

% (b) Brute force: enumerate every address for 200 random small ASes and compare
rng(1);
small = find(A_i <= 2^20);
pick  = small(randperm(numel(small), min(200, numel(small))));
for k = pick'
    rowsK = PL(g == k, :);
    addrs = cell(size(rowsK, 1), 1);
    for r = 1:size(rowsK, 1)
        addrs{r} = rowsK(r, 2) + (0:2^(32 - rowsK(r, 3)) - 1)';
    end
    assert(numel(unique(vertcat(addrs{:}))) == A_i(k), 'Brute-force mismatch for AS%d', ASN(k));
end
fprintf('Check (b) brute-force enumeration on %d random ASes: PASS\n', numel(pick));

% (c) Bounds: largest block <= A_i <= sum of block sizes; global <= 2^32 and <= sum of A_i
sumBlk = accumarray(g, 2 .^ (32 - PL(:, 3)));
maxBlk = accumarray(g, 2 .^ (32 - PL(:, 3)), [], @max);
assert(all(A_i <= sumBlk & A_i >= maxBlk) && globalA <= 2^32 && globalA <= sum(A_i));
fprintf('Check (c) bounds (max block <= A_i <= sum of blocks, global <= 2^32): PASS\n\n');

%% 7) Report --------------------------------------------------------------------------
fprintf('--- Data handling ---\n');
fprintf('Rows read                       : %d\n', nRows);
fprintf('Malformed rows skipped          : %d\n', nRows - nnz(valid));
fprintf('Rows with host bits set         : %d\n', nnz(hostBits));
fprintf('MOAS rows (''_'' in origin)       : %d\n', nnz(valid & isMOAS));
fprintf('AS-set rows ('','' in origin)      : %d\n', nnz(valid & isASset));
fprintf('Duplicate (AS,prefix) removed   : %d\n', nDupPairs);
fprintf('Distinct prefixes (global)      : %d\n', size(G, 1));
fprintf('Distinct (AS, prefix) pairs     : %d\n', size(PL, 1));
fprintf('Origin ASes                     : %d\n\n', numel(ASN));

fprintf('--- Address space ---\n');
fprintf('Global unique IPv4 addresses    : %s (%.2f%% of 2^32)\n', ...
        num2str(globalA, '%.0f'), 100 * globalA / 2^32);
fprintf('Sum of prefix sizes (no union)  : %s\n', num2str(sumSizes, '%.0f'));
fprintf('Sum of A_i over ASes            : %s (> global because of MOAS)\n\n', ...
        num2str(sum(A_i), '%.0f'));

T = table(ASN, P_i, A_i);
fprintf('Top 10 ASes by P_i:\n');  disp(head(sortrows(T, 'P_i', 'descend'), 10));
fprintf('Top 10 ASes by A_i:\n');  disp(head(sortrows(T, 'A_i', 'descend'), 10));

writetable(T, 'Task3a_PiAi.csv');
save('Task3a_PiAi.mat', 'T', 'PL', 'globalA');
fprintf('Saved Task3a_PiAi.csv and Task3a_PiAi.mat\n');

%% -------------------------------------------------------------------------------------
function added = unionAdded(grp, s, L)
% Number of NEW addresses each block adds to its group's union.
% Rows must be sorted by grp, then start s, then length L ascending (larger block first).
% Sweep: keep the furthest end seen so far in the group; a block starting past it is new,
% a block ending past it adds only the part beyond it, otherwise it adds nothing.
    n     = numel(s);
    e     = s + 2 .^ (32 - L) - 1;
    added = zeros(n, 1);
    curG  = NaN;
    mx    = -1;
    for k = 1:n
        if grp(k) ~= curG
            curG = grp(k);
            mx   = -1;
        end
        if s(k) > mx
            added(k) = e(k) - s(k) + 1;
            mx = e(k);
        elseif e(k) > mx
            added(k) = e(k) - mx;
            mx = e(k);
        end
    end
end