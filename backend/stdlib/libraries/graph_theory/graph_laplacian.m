function L = graph_laplacian(A)
    if nargin < 1, A = []; end
    D = diag(graph_degree(A));
    L = D - A;
end