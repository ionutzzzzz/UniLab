function c = matrix_condition_number(A)
    % MATRIX_CONDITION_NUMBER 2-norm condition number
    [~, S, ~] = svd(A);
    s = diag(S);
    c = max(s) / min(s);
end
