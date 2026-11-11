function c = matrix_condition_number(A)
    % MATRIX_CONDITION_NUMBER 2-norm condition number
    if nargin < 1, A = []; end
    [~, S, ~] = svd(A);
    s = diag(S);
    min_s = min(s);
    if min_s == 0
        c = Inf;
    else
        c = max(s) / min_s;
    end
end
