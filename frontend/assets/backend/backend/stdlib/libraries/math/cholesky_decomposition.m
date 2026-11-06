function L = cholesky_decomposition(A)
    % CHOLESKY_DECOMPOSITION Cholesky L matrix
    if nargin < 1, A = []; end
    L = chol(A, 'lower');
end
