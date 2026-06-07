function Q = orth_basis(A, tol)
    % ORTH_BASIS Orthonormal basis for the range of A
    if nargin < 2, tol = max(size(A)) * eps(norm_mat(A, 2)); end
    [U, S, ~] = svd(A);
    s = diag(S);
    r = sum(s > tol);
    Q = U(:, 1:r);
end
