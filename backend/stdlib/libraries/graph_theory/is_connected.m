function b = is_connected(A)
    L = graph_laplacian(A);
    e = sort(eig(L));
    b = e(2) > 1e-10;
end