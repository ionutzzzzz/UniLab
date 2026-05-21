function edges = adj_matrix_to_edge_list(A)
    [i, j, v] = find(A);
    edges = [i, j, v];
end