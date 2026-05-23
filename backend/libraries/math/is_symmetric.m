function b = is_symmetric(A)
    % IS_SYMMETRIC norm(A - A') < tol
    tol = 1e-6;
    b = norm(A - A') < tol;
end
