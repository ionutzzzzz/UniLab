function r = matrix_rank_approx(A, tol)
    % MATRIX_RANK_APPROX Approximate rank of a matrix
    if nargin < 2, tol = 1e-10; end
    [~, S, ~] = svd(A);
    s = diag(S);
    r = sum(s > tol);
end
