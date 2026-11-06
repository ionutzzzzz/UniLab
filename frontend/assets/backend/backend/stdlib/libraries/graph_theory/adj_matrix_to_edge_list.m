function edges = adj_matrix_to_edge_list(A)
    if nargin < 1, A = []; end
    [i, j, v] = find(A);
    edges = [i, j, v];
end