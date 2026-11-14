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
