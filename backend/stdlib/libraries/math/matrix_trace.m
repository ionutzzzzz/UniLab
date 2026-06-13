function t = matrix_trace(A)
    % MATRIX_TRACE sum(diag(A))
    if nargin < 1, A = []; end
    t = sum(diag(A));
end
