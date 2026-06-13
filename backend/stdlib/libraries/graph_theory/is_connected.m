function b = is_connected(A)
    if nargin < 1, A = []; end
    L = graph_laplacian(A);
    e = sort(eig(L));
    b = e(2) > 1e-10;
end