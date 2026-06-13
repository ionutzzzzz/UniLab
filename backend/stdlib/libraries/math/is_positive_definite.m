function b = is_positive_definite(A)
    % IS_POSITIVE_DEFINITE Check if all eigenvalues > 0
    if nargin < 1, A = []; end
    try
        chol(A);
        b = true;
    catch
        b = false;
    end
end
