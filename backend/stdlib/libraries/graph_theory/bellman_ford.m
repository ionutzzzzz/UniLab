function [dist, parent] = bellman_ford(A, start_node)
    % BELLMAN_FORD Shortest paths from single source
    if nargin < 1, A = []; end
    if nargin < 2, start_node = []; end
    n = size(A, 1);
    dist = inf(1, n);
    parent = zeros(1, n);
    dist(start_node) = 0;
    
    [u_idx, v_idx, w] = find(A);
    num_edges = length(u_idx);
    
    for i = 1:n-1
        for j = 1:num_edges
            u = u_idx(j); v = v_idx(j); weight = w(j);
            if dist(u) + weight < dist(v)
                dist(v) = dist(u) + weight;
                parent(v) = u;
            end
        end
    end
    
    % Check for negative cycles
    for j = 1:num_edges
        u = u_idx(j); v = v_idx(j); weight = w(j);
        if dist(u) + weight < dist(v)
            disp('Warning: Negative cycle detected');
        end
    end
end
