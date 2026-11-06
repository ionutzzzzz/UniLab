function A = edge_list_to_adj_matrix(edges, n)
    if nargin < 1, edges = []; end
    if nargin < 2, n = max(max(edges(:,1)), max(edges(:,2))); end
    A = zeros(n, n);
    for k = 1:size(edges, 1)
        A(edges(k,1), edges(k,2)) = edges(k,3);
    end
end