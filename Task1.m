%Task1 for Project2 baby!!
clear;
clc;
close all; % so I don't get the weird graph multiplying jerk again

% let's read these .txt-s!
data1 = readtable('20150801.as2types.txt', 'Delimiter', '|', 'CommentStyle', '#', 'ReadVariableNames', false);
data2 = readtable('20210401.as2types.txt', 'Delimiter', '|', 'CommentStyle', '#', 'ReadVariableNames', false);

% Let's name these columns so it's easier to read
data1.Properties.VariableNames = {'AS', 'Source', 'Type'};
data2.Properties.VariableNames = {'AS', 'Source', 'Type'};

% 3. Display some rows to see if it's working :3
disp(data1(1:5, :));

%% Part A: Totals, counts, and percentages -> let's make these tables!
total_2015 = height(data1);
total_2021 = height(data2);

% count each category for 2015 for out table
transit_2015 = sum(strcmp(data1.Type, 'Transit/Access'));
content_2015 = sum(strcmp(data1.Type, 'Content'));
enterprise_2015 = sum(strcmp(data1.Type, 'Enterprise'));

counts_2015 = [transit_2015, content_2015, enterprise_2015];
percentage_2015 = (counts_2015 / total_2015) * 100;

% count each category for 2021 for our table!
transit_2021 = sum(strcmp(data2.Type, 'Transit/Access'));
content_2021 = sum(strcmp(data2.Type, 'Content'));
enterprise_2021 = sum(strcmp(data2.Type, 'Enterprise'));

counts_2021 = [transit_2021, content_2021, enterprise_2021];
percentage_2021 = (counts_2021 / total_2021) * 100;

% print results to command window so we can get our el numeros
disp('--- 2015 Results ---');
disp(['Total ASes: ', num2str(total_2015)]);
disp('Counts (Transit/Access, Content, Enterprise):');
disp(counts_2015);
disp('Percentages:');
disp(percentage_2015);

disp('--- 2021 Results ---');
disp(['Total ASes: ', num2str(total_2021)]);
disp('Counts (Transit/Access, Content, Enterprise):');
disp(counts_2021);
disp('Percentages:');
disp(percentage_2021);
%% Part B: Graph 1 -> let's start setting up our pretty graphs
labels = categorical({'Transit/Access', 'Content', 'Enterprise'});
labels = reordercats(labels, {'Transit/Access', 'Content', 'Enterprise'});

% Create custom tick positions and pretty x10^4 labels
tick_vals = 0:10000:60000;
tick_text = {'0', '1\times10^4', '2\times10^4', '3\times10^4', ...
    '4\times10^4', '5\times10^4', '6\times10^4'};

% Picking 3 pretty colors had to google a bit to find the colors I wanted
bar_colors = [
    0.93, 0.32, 0.62;  % Bright Berry Pink (Transit/Access)
    0.48, 0.22, 0.78;  % Rich Violet Purple (Content)
    0.55, 0.65, 0.98   % Soft Periwinkle (Enterprise)
];

% because we are pretty pretty girlies 💅

figure; % let's get our figures going
subplot(1, 2, 1);
bar1 = bar(labels, counts_2015);
bar1.FaceColor = 'flat';
bar1.CData = bar_colors;
bar1.EdgeColor = 'none'; % says it helps remove the harsh black outline for a softer look, why not
title('2015 AS Categories');
ylabel('Number of ASes');
ylim([0 65000]);
yticks(tick_vals);
yticklabels(tick_text);
grid on;

subplot(1, 2, 2);
bar2 = bar(labels, counts_2021);
bar2.FaceColor = 'flat';
bar2.CData = bar_colors;
bar2.EdgeColor = 'none';
title('2021 AS Categories');
ylabel('Number of ASes');
ylim([0 65000]);
yticks(tick_vals);
yticklabels(tick_text);
grid on;

%% Part C: Check those percentage differences and count differences!
diff_counts = counts_2021 - counts_2015;
diff_percentage = percentage_2021 - percentage_2015;

disp('--- Change from 2015 to 2021 ---');
disp('Count Change:');
disp(diff_counts);
disp('Percentage Share Change:');
disp(diff_percentage);
