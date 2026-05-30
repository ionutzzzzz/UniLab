function b = is_unitary(A)
    % IS_UNITARY Check if A is a unitary matrix (U*U' = I)
    n = size(A, 1);
    I = eye(n);
    b = max(max(abs(A * A' - I))) < 1e-10;
end
