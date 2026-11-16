%ECE478Project2
%Task6 for Project2 baby!!
clear;
clc;
close all; % so I don't get the weird graph multiplying jerk again

% let's read the 2024 relationship .txt!
data = readtable('20241101.as-rel2.txt', 'Delimiter', '|', 'CommentStyle', '#', 'ReadVariableNames', false);

% Let's name these columns so it's easier to read
data.Properties.VariableNames = {'AS1', 'AS2', 'Rel', 'Source'};

% Display a few rows to make sure it loaded right :3
disp(data(1:5, :));

%% Part A: Build the undirected 2024 AS graph
all_ases = unique([data.AS1; data.AS2]);
num_as = length(all_ases);

[~, idx1] = ismember(data.AS1, all_ases);
[~, idx2] = ismember(data.AS2, all_ases);

% Skip self-loops and build an undirected adjacency matrix
valid_edges = (idx1 ~= idx2);
u = idx1(valid_edges);
v = idx2(valid_edges);
adj_mat = sparse([u; v], [v; u], 1, num_as, num_as);
adj_mat = spones(adj_mat);

% Initial global degree before we knock anything out
orig_deg = full(sum(adj_mat, 2));

%% Part B: Targeted removal vs. Random failures
f_vals = [0, 0.01, 0.02, 0.05, 0.10];
num_f = length(f_vals);
num_trials = 15; % needs at least 10 seeded trials

R_targeted = zeros(1, num_f);
R_rand_trials = zeros(num_trials, num_f);

% Sort ASes in descending global-degree order (before removal)
[~, high_deg_order] = sort(orig_deg, 'descend');

% 1. Descending global-degree removal
for k = 1:num_f
    f = f_vals(k);
    num_remove = round(f * num_as);
    
    surviving = true(num_as, 1);
    if num_remove > 0
        surviving(high_deg_order(1:num_remove)) = false;
    end
    
    % Cut down to surviving ASes and check remaining global degrees
    sub_adj = adj_mat(surviving, surviving);
    sub_deg = full(sum(sub_adj, 2));
    
    % Crude LCC approx = surviving ASes with global degree > 0
    num_surviving = sum(surviving);
    approx_lcc = sum(sub_deg > 0);
    R_targeted(k) = approx_lcc / num_surviving;
end

% 2. Random removal averaged over 15 independently seeded trials
for t = 1:num_trials
    rng(t); % different seed per trial
    rand_order = randperm(num_as);
    
    for k = 1:num_f
        f = f_vals(k);
        num_remove = round(f * num_as);
        
        surviving = true(num_as, 1);
        if num_remove > 0
            surviving(rand_order(1:num_remove)) = false;
        end
        
        sub_adj = adj_mat(surviving, surviving);
        sub_deg = full(sum(sub_adj, 2));
        
        num_surviving = sum(surviving);
        approx_lcc = sum(sub_deg > 0);
        R_rand_trials(t, k) = approx_lcc / num_surviving;
    end
end

R_rand_mean = mean(R_rand_trials, 1);
R_rand_std  = std(R_rand_trials, 0, 1);
R_rand_min  = min(R_rand_trials, [], 1);
R_rand_max  = max(R_rand_trials, [], 1);

% print results to command window so we can get our el numeros
disp('--- Task 6 Robustness Results ---');
results_table = table(f_vals', R_targeted', R_rand_mean', R_rand_std', R_rand_min', R_rand_max', ...
    'VariableNames', {'f', 'Targeted_R', 'Random_Mean', 'Random_Std', 'Random_Min', 'Random_Max'});
disp(results_table);

%% Part C: Plot R(f) -> let's start setting up our pretty graph
% Using the pretty colors from Task 1 because we are pretty pretty girlies 💅
pink_color   = [0.93, 0.32, 0.62]; % Bright Berry Pink (Random failures)
purple_color = [0.48, 0.22, 0.78]; % Rich Violet Purple (Targeted removal)

figure; % let's get our figures going
hold on;

% Plot random removal with +/- 1 std dev error bars
errorbar(f_vals * 100, R_rand_mean, R_rand_std, '-o', ...
    'Color', pink_color, 'LineWidth', 2, 'MarkerSize', 7, ...
    'MarkerFaceColor', pink_color, 'CapSize', 8);

% Plot descending global-degree removal
plot(f_vals * 100, R_targeted, '-s', ...
    'Color', purple_color, 'LineWidth', 2, 'MarkerSize', 7, ...
    'MarkerFaceColor', purple_color);

title('Structural Robustness: Random vs. Descending-Degree AS Removal');
xlabel('Percentage of Removed ASes (%)');
ylabel('Surviving Connected Fraction R(f)');
legend({'Random Failure (Mean \pm 1 SD, 15 trials)', 'Descending-Degree Removal'}, ...
    'Location', 'southwest');
xticks(f_vals * 100);
ylim([0 1.05]);
grid on;
hold off;

saveas(gcf, 'task6_robustness.png');
