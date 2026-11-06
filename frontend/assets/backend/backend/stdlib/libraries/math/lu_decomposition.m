function [L, U] = lu_decomposition(A)
    % LU_DECOMPOSITION LU decomposition of a square matrix A
    % A = L * U
    
    if nargin < 1, A = []; end
    [n, m] = size(A);
    L = eye(n);
    U = A;
    
    for i = 1:n
        for j = i+1:n
            factor = U(j, i) / U(i, i);
            L(j, i) = factor;
            U(j, :) = U(j, :) - factor * U(i, :);
        end
    end
end
