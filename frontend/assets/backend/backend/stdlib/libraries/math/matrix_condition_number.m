function c = matrix_condition_number(A)
    % MATRIX_CONDITION_NUMBER norm(A) * norm(inv(A))
    if nargin < 1, A = []; end
    c = cond(A);
end
