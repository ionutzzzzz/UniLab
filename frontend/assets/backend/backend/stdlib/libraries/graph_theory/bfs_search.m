function [order, parent] = bfs_search(A, start_node)
    % BFS_SEARCH Breadth-First Search traversal
    if nargin < 1, A = []; end
    if nargin < 2, start_node = []; end
    n = size(A, 1);
    visited = false(1, n);
    order = [];
    parent = zeros(1, n);
    queue = [start_node];
    visited(start_node) = true;
    
    while ~isempty(queue)
        u = queue(1); queue(1) = [];
        order = [order, u];
        neighbors = find(A(u, :));
        for v = neighbors
            if ~visited(v)
                visited(v) = true;
                parent(v) = u;
                queue = [queue, v];
            end
        end
    end
end
