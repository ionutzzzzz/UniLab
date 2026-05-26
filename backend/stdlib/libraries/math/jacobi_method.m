function [x] = jacobi_method(A, b, x0, tol, max_iters)
    % JACOBI_METHOD Iterative solver for linear systems Ax = b
    
    n = length(b);
    x = x0;
    D = diag(diag(A));
    R = A - D;
    
    for i = 1:max_iters
        x_new = inv(D) * (b - R * x);
        if norm(x_new - x) < tol
            x = x_new;
            break;
        end
        x = x_new;
    end
end
