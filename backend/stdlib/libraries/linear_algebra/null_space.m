function Z = null_space(A, tol)
    % NULL_SPACE Orthonormal basis for the null space
    if nargin < 1, A = []; end
    if nargin < 2, tol = max(size(A)) * eps(norm_mat(A, 2)); end
    [U, S, V] = svd(A);
    s = diag(S);
    if isempty(s)
        Z = eye(size(A, 2));
    else
        idx = find(s <= tol);
        r = length(s) - length(idx);
        Z = V(:, r+1:end);
    end
end
