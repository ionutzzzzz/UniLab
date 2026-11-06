function [order, parent] = dfs_search(A, start_node)
    % DFS_SEARCH Depth-First Search traversal
    if nargin < 1, A = []; end
    if nargin < 2, start_node = []; end
    n = size(A, 1);
    visited = false(1, n);
    order = [];
    parent = zeros(1, n);
    
    [order, visited, parent] = dfs_visit(A, start_node, visited, order, parent);
end

function [order, visited, parent] = dfs_visit(A, u, visited, order, parent)
    if nargin < 1, A = []; end
    if nargin < 2, u = []; end
    if nargin < 3, visited = []; end
    if nargin < 4, order = []; end
    if nargin < 5, parent = []; end
    visited(u) = true;
    order = [order, u];
    neighbors = find(A(u, :));
    for v = neighbors
        if ~visited(v)
            parent(v) = u;
            [order, visited, parent] = dfs_visit(A, v, visited, order, parent);
        end
    end
end
