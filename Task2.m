%ECE478 Project2
%Task2 for Project2 baby!!
clear;
clc;
close all;

%% 1. Load the relationship dataset
% Format: AS1 | AS2 | relationship (-1 = p2c, 0 = p2p) | source
data = readtable('20241101.as-rel2.txt', 'Delimiter', '|', 'CommentStyle', '#', 'ReadVariableNames', false);
data.Properties.VariableNames = {'AS1', 'AS2', 'Rel', 'Source'};

disp('First 5 rows:');
disp(data(1:5, :));

%% Part A: Let's compute all these (four) degrees and check their identities
% First we must find every unique AS number in the dataset
all_AS = unique([data.AS1; data.AS2]);
num_AS = length(all_AS);
