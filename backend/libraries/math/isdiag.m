function b = isdiag(A)
    % ISDIAG Determine if matrix is diagonal
    if size(A, 1) ~= size(A, 2)
        b = false;
        return;
    end
    b = all(all(A - diag(diag(A)) == 0));
end
