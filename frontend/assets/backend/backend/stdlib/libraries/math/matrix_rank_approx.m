function r = matrix_rank_approx(A)
    % MATRIX_RANK_APPROX Count non-zero eigenvalues or similar
    if nargin < 1, A = []; end
    r = rank(A);
end
