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
