function b = istriu(A)
    % ISTRIU Determine if matrix is upper triangular
    if nargin < 1, A = []; end
    b = all(all(tril(A, -1) == 0));
end
