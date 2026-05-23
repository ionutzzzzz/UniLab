function c = matrix_condition_number(A)
    % MATRIX_CONDITION_NUMBER norm(A) * norm(inv(A))
    c = cond(A);
end
