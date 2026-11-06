function [mst_edges, total_weight] = kruskal_algorithm(A)
    % KRUSKAL_ALGORITHM Minimum Spanning Tree
    if nargin < 1, A = []; end
    n = size(A, 1);
    [u, v, w] = find(triu(A));
    edges = [u, v, w];
    [~, idx] = sort(edges(:, 3));
    edges = edges(idx, :);
    
    parent = 1:n;
    mst_edges = [];
    total_weight = 0;
    
    for i = 1:size(edges, 1)
        u_node = edges(i, 1);
        v_node = edges(i, 2);
        
        % Find set with path compression (iterative)
        curr = u_node;
        while parent(curr) ~= curr
            curr = parent(curr);
        end
        root1 = curr;
        
        curr = v_node;
        while parent(curr) ~= curr
            curr = parent(curr);
        end
        root2 = curr;
        
        if root1 ~= root2
            mst_edges = [mst_edges; edges(i, :)];
            total_weight = total_weight + edges(i, 3);
            parent(root1) = root2;
        end
    end
end
