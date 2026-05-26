function b = is_positive_definite(A)
    % IS_POSITIVE_DEFINITE Check if all eigenvalues > 0
    try
        chol(A);
        b = true;
    catch
        b = false;
    end
end
