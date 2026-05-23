% 56_graph_theory_social_analysis.m
% UniLab Graph Theory: Social Network Centrality & Topology

clear all;
clc;

disp('🕸️ UniLab Social Network Analysis');
disp('==================================');

%% 1. Network Initialization
disp('--- 1. Constructing Collaboration Graph ---');
% Small social graph (7 nodes)
% 1-2, 1-3, 2-3, 3-4, 4-5, 4-6, 5-6, 5-7, 6-7
edges = [1, 2, 1;
         1, 3, 1;
         2, 3, 1;
         3, 4, 1;
         4, 5, 1;
         4, 6, 1;
         5, 6, 1;
         5, 7, 1;
         6, 7, 1];

A = edge_list_to_adj_matrix(edges, 7);
% Make undirected
A = A + A';
A(A > 1) = 1;

disp('Adjacency Matrix:');
disp(A);

%% 2. Network Topology
disp('--- 2. Network Connectivity & Density ---');
dens = graph_density(A);
fprintf('Network Density: %.4f\n', dens);

if is_connected(A)
    disp('Status: The social network is fully connected.');
else
    disp('Status: The social network is fragmented.');
end

diam = graph_diameter(A);
fprintf('Network Diameter (Max degrees of separation): %d\n', diam);

%% 3. Centrality Metrics
disp(' ');
disp('--- 3. Identifying Influencers (Centrality) ---');

% PageRank (Popularity)
pr = page_rank_simple(A);

% Closeness (Access to information)
cl = closeness_centrality(A);

% Degree (Immediate connections)
deg = graph_degree(A);

disp('Node Analysis:');
fprintf('Node | Degree | PageRank | Closeness\n');
fprintf('-----|--------|----------|----------\n');
for i = 1:7
    fprintf('  %d  |   %d    |  %.4f  |  %.4f\n', i, deg(i), pr(i), cl(i));
end

[~, best_pr] = max(pr);
[~, best_cl] = max(cl);

fprintf('\nMost Influential Node (PageRank):  %d\n', best_pr);
fprintf('Most Integrated Node (Closeness): %d\n', best_cl);

%% 4. Communities
disp(' ');
disp('--- 4. Community Detection (Laplacian Spectrum) ---');
L = graph_laplacian(A);
[V, D] = eig(L);
% Fiedler vector (eigenvector of second smallest eigenvalue) is V(:, 2)
fiedler = V(:, 2);

disp('Fiedler Vector (Partitioning):');
disp(fiedler');

disp('Network Analysis Complete.');
