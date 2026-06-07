function b = is_orthogonal_set(V, tol)
    % IS_ORTHOGONAL_SET Check if columns of V are orthogonal
    if nargin < 2, tol = 1e-10; end
    n = size(V, 2);
    prod = V' * V;
    b = all(all(abs(prod - diag(diag(prod))) < tol));
end
