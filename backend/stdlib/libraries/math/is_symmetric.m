function b = is_symmetric(A)
    % IS_SYMMETRIC norm(A - A') < tol
    if nargin < 1, A = []; end
    tol = 1e-6;
    b = norm(A - A') < tol;
end
