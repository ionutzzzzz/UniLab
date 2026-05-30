function b = is_positive_definite(A)
    % IS_POSITIVE_DEFINITE Check if A is positive definite using eigenvalues
    e = eig(A);
    b = all(e > 0);
end
