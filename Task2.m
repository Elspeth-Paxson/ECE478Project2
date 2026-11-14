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

% Next, we must map AS numbers to a nice clean row indices 1..num_AS for fast counting
[~, idx1] = ismember(data.AS1, all_AS);
[~, idx2] = ismember(data.AS2, all_AS);

% was having issues, much googling later and it said this would help
% Separate p2c (-1) and p2p (0) links
is_p2c = (data.Rel == -1);
is_p2p = (data.Rel == 0);

% Now we need to count customers d(c), providers d(r), and peers d(p) for each and eveyr AS
d_customer = accumarray(idx1(is_p2c), 1, [num_AS, 1]);
d_provider = accumarray(idx2(is_p2c), 1, [num_AS, 1]);
d_peer = accumarray([idx1(is_p2p); idx2(is_p2p)], 1, [num_AS, 1]);

% Count distinct neighbors (global degree d_i)
pairs = [idx1, idx2; idx2, idx1];
unique_pairs = unique(pairs, 'rows');
d_global = accumarray(unique_pairs(:, 1), 1, [num_AS, 1]);

% Validate d_i = d(c)_i + d(p)_i + d(r)_i
sum_parts = d_customer + d_peer + d_provider;
violations = sum(d_global ~= sum_parts);  %let's check those violations

disp('--- Part A: Identity Validation ---');
disp(['Total unique ASes: ', num2str(num_AS)]);
disp(['Number of ASes violating d_i = d(c) + d(p) + d(r): ', num2str(violations)]);

%% Part B: Now we get out lovely Graph 2 (Four Degree Histograms with Custom Bins)
% Bins: 0, 1, 2-5, 6-100, 101-500, 501-1000, > 1000 like projecct paper boss says to do
bin_labels = {'0', '1', '2-5', '6-100', '101-500', '501-1000', '> 1000'};
bin_cats = categorical(bin_labels, bin_labels); % meow

% Helper edges so discretize groups integers cleanly:, said edges would
% help
% [-0.5, 0.5) -> 0 | [0.5, 1.5) -> 1 | [1.5, 5.5) -> 2-5 | etc.
edges = [-0.5, 0.5, 1.5, 5.5, 100.5, 500.5, 1000.5, inf];

c_global = histcounts(d_global, edges);
c_cust   = histcounts(d_customer, edges);
c_peer   = histcounts(d_peer, edges);
c_prov   = histcounts(d_provider, edges);

figure('Name', 'Graph 2: AS Degree Histograms');

subplot(2, 2, 1);
bar(bin_cats, c_global, 'FaceColor', [0.95, 0.30, 0.60], 'EdgeColor', 'none');
title('Global Degree d_i');
ylabel('Number of ASes'); % haha Ases
grid on;

subplot(2, 2, 2);
bar(bin_cats, c_cust, 'FaceColor', [0.45, 0.15, 0.75], 'EdgeColor', 'none');
title('Customer Degree d^{(c)}_i');
ylabel('Number of ASes');
grid on;

subplot(2, 2, 3);
bar(bin_cats, c_peer, 'FaceColor', [0.75, 0.35, 0.85], 'EdgeColor', 'none');
title('Peer Degree d^{(p)}_i');
ylabel('Number of ASes');
grid on;

subplot(2, 2, 4);
bar(bin_cats, c_prov, 'FaceColor', [0.95, 0.60, 0.80], 'EdgeColor', 'none');
title('Provider Degree d^{(r)}_i');
ylabel('Number of ASes');
grid on;

%% Part C: Now we get out lovely Graph 3 (CCDF of Global AS Degree on Log-Log Axes)
d_pos = d_global(d_global >= 1); % k >= 1
k_vals = sort(unique(d_pos));
ccdf = zeros(size(k_vals));

for i = 1:length(k_vals)
    ccdf(i) = sum(d_pos >= k_vals(i)) / length(d_pos);
end

figure('Name', 'Graph 3: Global AS Degree CCDF');
loglog(k_vals, ccdf, 'LineWidth', 2, 'Color', [0.85, 0.20, 0.55]);
title('CCDF of Global AS Degree Pr(D \geq k)');
xlabel('Global Degree k (log scale)');
ylabel('Pr(D \geq k) (log scale)');
grid on;

% Summary statistics that we can use for our table in the project report
mean_d   = mean(d_global);
median_d = median(d_global);
p95_d    = prctile(d_global, 95);
max_d    = max(d_global);

disp('--- Part C: Global Degree Statistics ---');
disp(['Mean: ', num2str(mean_d)]);
disp(['Median: ', num2str(median_d)]);
disp(['95th Percentile: ', num2str(p95_d)]);
disp(['Maximum: ', num2str(max_d)]);

%% Part D last stop!: Top 10 Highest-Global-Degree ASes to make our table for part d!
T_deg = table(all_AS, d_global, d_customer, d_peer, d_provider, ...
    'VariableNames', {'AS', 'Global_d', 'Customer_dc', 'Peer_dp', 'Provider_dr'});

T_sorted = sortrows(T_deg, 'Global_d', 'descend');

disp('--- Part D: Top 10 Highest-Global-Degree ASes ---');
disp(T_sorted(1:10, :));
