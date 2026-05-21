function b = istriu(A)
    % ISTRIU Determine if matrix is upper triangular
    b = all(all(tril(A, -1) == 0));
end
