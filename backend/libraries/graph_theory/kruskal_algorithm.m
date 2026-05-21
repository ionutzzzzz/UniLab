function [mst_edges, total_weight] = kruskal_algorithm(A)
    % KRUSKAL_ALGORITHM Minimum Spanning Tree
    n = size(A, 1);
    [u, v, w] = find(triu(A));
    edges = [u, v, w];
    [~, idx] = sort(edges(:, 3));
    edges = edges(idx, :);
    
    parent = 1:n;
    mst_edges = [];
    total_weight = 0;
    
    function p = find_set(i)
        if parent(i) == i, p = i; else, parent(i) = find_set(parent(i)); p = parent(i); end
    end
    
    for i = 1:size(edges, 1)
        root1 = find_set(edges(i, 1));
        root2 = find_set(edges(i, 2));
        if root1 ~= root2
            mst_edges = [mst_edges; edges(i, :)];
            total_weight = total_weight + edges(i, 3);
            parent(root1) = root2;
        end
    end
end
