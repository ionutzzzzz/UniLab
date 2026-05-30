function b = istril(A)
    % ISTRIL Determine if matrix is lower triangular
    b = all(all(triu(A, 1) == 0));
end
