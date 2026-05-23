% 49_graph_theory_networks.m
% UniLab Graph Theory: Network Analysis and Routing

clear all;
clc;

disp('🕸️ UniLab Graph Theory: Network Analysis');
disp('======================================');

disp('--- 1. Network Initialization ---');
% Construct adjacency matrix for a weighted graph with 6 nodes
n_nodes = 6;
A = zeros(n_nodes, n_nodes);
A(1,2) = 4; A(1,3) = 2;
A(2,3) = 5; A(2,4) = 10;
A(3,5) = 3;
A(4,6) = 11;
A(5,4) = 4; A(5,6) = 5;

% Make the graph undirected and symmetric
A = A + A'; 

disp('Adjacency Matrix representing Network Topology:');
disp(A);

disp('--- 2. Shortest Path Routing (Dijkstra) ---');
start_node = 1;
[dist, path] = dijkstra(A, start_node);

fprintf('Shortest distances from Origin Node %d:\n', start_node);
for i = 1:n_nodes
    if i ~= start_node
        fprintf('  To Node %d: Path Cost = %d\n', i, dist(i));
    end
end

disp(' ');
disp('--- 3. Minimum Spanning Tree (Kruskal) ---');
[mst_edges, total_weight] = kruskal_algorithm(A);
fprintf('Total network cost for Minimum Spanning Tree: %d\n', total_weight);
disp('MST Edges [Node U, Node V, Weight]:');
disp(mst_edges);

disp(' ');
disp('--- 4. PageRank Centrality ---');
% Create a directed web-graph representation for PageRank
A_dir = zeros(n_nodes, n_nodes);
A_dir(1,2) = 1; A_dir(1,3) = 1;
A_dir(2,4) = 1; A_dir(3,5) = 1;
A_dir(4,6) = 1; A_dir(5,4) = 1; A_dir(5,6) = 1; A_dir(6,1) = 1;

pr = page_rank_simple(A_dir);
disp('PageRank Centrality Scores:');
for i = 1:n_nodes
    fprintf('  Node %d: %.4f\n', i, pr(i));
end

disp('Network Analysis complete.');