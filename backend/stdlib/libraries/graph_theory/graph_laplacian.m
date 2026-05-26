function L = graph_laplacian(A)
    D = diag(graph_degree(A));
    L = D - A;
end