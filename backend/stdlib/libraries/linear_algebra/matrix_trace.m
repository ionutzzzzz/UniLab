function t = matrix_trace(M)
    if nargin < 1, M = []; end
    t = sum(diag(M));
end
