%ECE478 Project2
%Task4 for Project2 baby!!
clear;
clc;
close all;
format long g; % no scientific notation!

%% Part A Let's Go: Load & clean the relationship dataset
% Format: AS1 | AS2 | relationship (-1 = p2c, 0 = p2p) | source
rawRel = readtable('20241101.as-rel2.txt', 'Delimiter', '|', 'CommentStyle', '#', 'ReadVariableNames', false);
rawRel.Properties.VariableNames = {'AS1', 'AS2', 'Rel', 'Source'};

% Clean out any malformed rows & self-links (Rules 1 & 3)
validRows = ~isnan(rawRel.AS1) & ~isnan(rawRel.AS2) & ismember(rawRel.Rel, [-1, 0]);
rawRel = rawRel(validRows, :);

selfLinks = (rawRel.AS1 == rawRel.AS2);
fprintf('Excluded self-links: %d\n', sum(selfLinks));
rawRel = rawRel(~selfLinks, :);

% Deduplicate ignoring Source column (Rule 2)
% Normalize p2p order so (A,B,0) and (B,A,0) count as the same link
p2pMask = (rawRel.Rel == 0);
minAS = min(rawRel.AS1(p2pMask), rawRel.AS2(p2pMask));
maxAS = max(rawRel.AS1(p2pMask), rawRel.AS2(p2pMask));
rawRel.AS1(p2pMask) = minAS;
rawRel.AS2(p2pMask) = maxAS;

[~, uniqueIdx] = unique(rawRel(:, {'AS1', 'AS2', 'Rel'}), 'rows', 'stable');
fprintf('Excluded duplicate link records: %d\n', height(rawRel) - length(uniqueIdx));
data = rawRel(uniqueIdx, :);

% Get all unique ASes in the 2024 graph
allASNs = unique([data.AS1; data.AS2]);
numAS = length(allASNs);

% Count customer and peer degrees
custDeg = zeros(numAS, 1);
peerDeg = zeros(numAS, 1);

[~, idx1] = ismember(data.AS1, allASNs);
[~, idx2] = ismember(data.AS2, allASNs);

for i = 1:height(data)
    if data.Rel(i) == -1
        % AS1 is provider, AS2 is customer
        custDeg(idx1(i)) = custDeg(idx1(i)) + 1;
    elseif data.Rel(i) == 0
        % peer-to-peer link
        peerDeg(idx1(i)) = peerDeg(idx1(i)) + 1;
        peerDeg(idx2(i)) = peerDeg(idx2(i)) + 1;
    end
end

% Assign structural labels
structRole = strings(numAS, 1);
for i = 1:numAS
    if custDeg(i) > 0
        structRole(i) = "Customer-serving";
    elseif peerDeg(i) > 0
        structRole(i) = "Peering edge";
    else
        structRole(i) = "Stub/Multi-homed";
    end
end

%% 2. Load & clean the classification dataset (2021 file confirmed!)
% Format: ASN | Source | BusinessType
typesData = readtable('20210401.as2types.txt', 'Delimiter', '|', 'CommentStyle', '#', 'ReadVariableNames', false);
typesData.Properties.VariableNames = {'ASN', 'Source', 'Type'};
typesData.Type = strtrim(string(typesData.Type));

% Clean out any malformed or duplicate ASN rows
typesData = typesData(~isnan(typesData.ASN) & strlength(typesData.Type) > 0, :);
[~, uniqueTypeIdx] = unique(typesData.ASN, 'stable');
fprintf('Excluded duplicate classification records: %d\n\n', height(typesData) - length(uniqueTypeIdx));
typesData = typesData(uniqueTypeIdx, :);

%% 3. Part A: Match ASes and build 3x3 contingency table
[matchedASNs, idxRel, idxType] = intersect(allASNs, typesData.ASN);

onlyInRel = length(allASNs) - length(matchedASNs);
onlyInType = height(typesData) - length(matchedASNs);

fprintf('Total in 2024 rel file: %d\n', length(allASNs));
fprintf('Total in classification file: %d\n', height(typesData));
fprintf('Matched sample size: %d\n', length(matchedASNs));
fprintf('Excluded (only in 2024 graph): %d\n', onlyInRel);
fprintf('Excluded (only in class file): %d\n\n', onlyInType);

matchedStruct = structRole(idxRel);
matchedBus = typesData.Type(idxType);

% Build 3x3 table
bNames = ["Transit/Access", "Content", "Enterprise"];
sNames = ["Customer-serving", "Peering edge", "Stub/Multi-homed"];
table3x3 = zeros(3, 3);

for r = 1:3
    for c = 1:3
        table3x3(r, c) = sum(matchedBus == bNames(r) & matchedStruct == sNames(c));
    end
end

% Sanity check to make sure every matched AS landed in the 3x3 table
assert(sum(table3x3(:)) == length(matchedASNs), 'Warning: Some ASes did not match bNames or sNames!');

T = array2table(table3x3, 'RowNames', bNames, 'VariableNames', sNames);
disp('3x3 Contingency Table:');
disp(T);

%% 4. Part B: Graph 5 (Normalized stacked bar chart)
rowSums = sum(table3x3, 2);
pctMatrix = (table3x3 ./ rowSums) * 100;

figure('Color', 'w');
b = bar(pctMatrix, 'stacked', 'BarWidth', 0.55);

% pretty colors for bar graph
b(1).FaceColor = [0.36 0.17 0.44]; % Amethyst Purple
b(2).FaceColor = [0.07 0.47 0.39]; % Emerald Green
b(3).FaceColor = [0.12 0.38 0.55]; % Sapphire Blue

% Add percentage labels inside each bar segment
for i = 1:3
    yPos = 0;
    for j = 1:3
        val = pctMatrix(i, j);
        if val > 3
            text(i, yPos + val/2, sprintf('%.1f%%', val), ...
                'HorizontalAlignment', 'center', ...
                'Color', 'w', 'FontWeight', 'bold', 'FontSize', 10);
        end
        yPos = yPos + val;
    end
end

xticks([1 2 3]);
xticklabels(bNames);
xlabel('Business Classification', 'FontWeight', 'bold');
ylabel('Percentage of ASes (%)', 'FontWeight', 'bold');
title(['Graph 5: Structural Roles by Business Class (N = ', num2str(length(matchedASNs)), ')']);
legend(sNames, 'Location', 'eastoutside');
ylim([0 100]);
grid on;

saveas(gcf, 'graph5.png'); % good to save

%% 5. Part C: Print unexpected examples to investigate!
disp('Sample Content ASes with Customer-serving role:');
idxEx1 = find(matchedBus == "Content" & matchedStruct == "Customer-serving");
disp(matchedASNs(idxEx1(1:min(5, end))));

disp('Sample Enterprise ASes with Customer-serving role:');
idxEx2 = find(matchedBus == "Enterprise" & matchedStruct == "Customer-serving");
disp(matchedASNs(idxEx2(1:min(5, end))));

disp('Sample Transit/Access ASes with Stub/Multi-homed role:');
idxEx3 = find(matchedBus == "Transit/Access" & matchedStruct == "Stub/Multi-homed");
disp(matchedASNs(idxEx3(1:min(5, end))));

%% Get exact degree counts for 3 fresh 2021+2024 examples! So we can use them ine xamples!
freshExamples = [matchedASNs(idxEx1(1)), matchedASNs(idxEx2(1)), matchedASNs(idxEx3(1))];

for asn = freshExamples(:)'
    idx = find(allASNs == asn);
    provDeg = sum(data.AS2 == asn & data.Rel == -1);
    busType = typesData.Type(typesData.ASN == asn);
    fprintf('AS%d | 2021 Class: %s | 2024 Role: %s -> Providers: %d, Peers: %d, Customers: %d\n', ...
        asn, busType, structRole(idx), provDeg, peerDeg(idx), custDeg(idx));
end


