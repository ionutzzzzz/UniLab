function [x] = gauss_seidel(A, b, x0, tol, max_iters)
    % GAUSS_SEIDEL Iterative solver for linear systems Ax = b
    
    n = length(b);
    x = x0;
    
    for k = 1:max_iters
        x_old = x;
        for i = 1:n
            sum_val = 0;
            for j = 1:n
                if i ~= j
                    sum_val = sum_val + A(i, j) * x(j);
                end
            end
            x(i) = (b(i) - sum_val) / A(i, i);
        end
        
        if norm(x - x_old) < tol
            break;
        end
    end
end
