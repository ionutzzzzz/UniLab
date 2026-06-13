function b = istril(A)
    % ISTRIL Determine if matrix is lower triangular
    if nargin < 1, A = []; end
    b = all(all(triu(A, 1) == 0));
end
