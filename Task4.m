%ECE478 Project2
%Task2 for Project2 baby!!
clear;
clc;
close all;

%% Part A Let's Go:  Load the relationship dataset
% Format: AS1 | AS2 | relationship (-1 = p2c, 0 = p2p) | source
data = readtable('20241101.as-rel2.txt', 'Delimiter', '|', 'CommentStyle', '#', 'ReadVariableNames', false);
data.Properties.VariableNames = {'AS1', 'AS2', 'Rel', 'Source'};

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

%% 2. Load the classification dataset
% Format: ASN | Source | BusinessType
typesData = readtable('20150801.as2types.txt', 'Delimiter', '|', 'CommentStyle', '#', 'ReadVariableNames', false);
typesData.Properties.VariableNames = {'ASN', 'Source', 'Type'};
typesData.Type = string(typesData.Type);

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
        text(i, yPos + val/2, sprintf('%.1f%%', val), ...
            'HorizontalAlignment', 'center', ...
            'Color', 'w', 'FontWeight', 'bold', 'FontSize', 10);
        yPos = yPos + val;
    end
end

xticklabels(bNames);
xlabel('Business Classification', 'FontWeight', 'bold');
ylabel('Percentage of ASes (%)', 'FontWeight', 'bold');
title('Graph 5: Structural Roles by Business Class');
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

%%  Get some values me hoy

for asn = [714, 33, 9]
    idx = find(allASNs == asn);
    provDeg = sum(data.AS2 == asn & data.Rel == -1);
    fprintf('AS%d -> Providers: %d, Peers: %d, Customers: %d\n', asn, provDeg, peerDeg(idx), custDeg(idx));
end

