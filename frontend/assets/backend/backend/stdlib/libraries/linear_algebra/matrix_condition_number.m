function c = matrix_condition_number(A)
    % MATRIX_CONDITION_NUMBER 2-norm condition number
    if nargin < 1, A = []; end
    [~, S, ~] = svd(A);
    s = diag(S);
    c = max(s) / min(s);
end
