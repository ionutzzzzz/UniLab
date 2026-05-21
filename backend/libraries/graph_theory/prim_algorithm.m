function [mst_edges, total_weight] = prim_algorithm(A, start_node)
    % PRIM_ALGORITHM Minimum Spanning Tree
    n = size(A, 1);
    visited = false(1, n);
    mst_edges = [];
    total_weight = 0;
    
    dist = inf(1, n);
    parent = zeros(1, n);
    dist(start_node) = 0;
    
    for i = 1:n
        [~, u] = min(dist + visited * 1e9);
        visited(u) = true;
        if parent(u) ~= 0
            mst_edges = [mst_edges; parent(u), u, A(parent(u), u)];
            total_weight = total_weight + A(parent(u), u);
        end
        
        neighbors = find(A(u, :));
        for v = neighbors
            if ~visited(v) && A(u, v) < dist(v)
                dist(v) = A(u, v);
                parent(v) = u;
            end
        end
    end
end
