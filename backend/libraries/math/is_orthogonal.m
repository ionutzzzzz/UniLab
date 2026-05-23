function b = is_orthogonal(A)
    % IS_ORTHOGONAL norm(A'*A - I) < tol
    [m, n] = size(A);
    if m ~= n
        b = false;
        return;
    end
    tol = 1e-6;
    b = norm(A' * A - eye(n)) < tol;
end
