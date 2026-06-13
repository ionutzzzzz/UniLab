function [x, i] = conjugate_gradient_method(A, b, x0, tol, max_iters)
    % CONJUGATE_GRADIENT_METHOD Solver for Ax = b, A must be SPD
    if nargin < 1, A = []; end
    if nargin < 2, b = []; end
    if nargin < 3, x0 = []; end
    if nargin < 4, tol = []; end
    if nargin < 5, max_iters = []; end
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
