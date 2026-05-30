function [x, i] = conjugate_gradient_method(A, b, x0, tol, max_iters)
    % CONJUGATE_GRADIENT_METHOD Solver for Ax = b, A must be SPD
    r = b - A * x0;
    p = r;
    x = x0;
    rsold = r' * r;
    
    for i = 1:max_iters
        Ap = A * p;
        alpha = rsold / (p' * Ap);
        x = x + alpha * p;
        r = r - alpha * Ap;
        rsnew = r' * r;
        if sqrt(rsnew) < tol
            break;
        end
        p = r + (rsnew / rsold) * p;
        rsold = rsnew;
    end
end
