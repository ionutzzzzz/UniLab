function L = cholesky_decomposition(A)
    % CHOLESKY_DECOMPOSITION Compute Cholesky factor L such that A = L*L'
    % A must be Hermitian and positive-definite
    n = size(A, 1);
    L = zeros(n, n);
    for i = 1:n
        for j = 1:i
            sum_val = sum(L(i, 1:j-1) .* L(j, 1:j-1));
            if i == j
                L(i, j) = sqrt(A(i, i) - sum_val);
            else
                L(i, j) = (A(i, j) - sum_val) / L(j, j);
            end
        end
    end
end
