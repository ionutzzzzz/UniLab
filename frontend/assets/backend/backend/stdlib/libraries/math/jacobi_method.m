function [x] = jacobi_method(A, b, x0, tol, max_iters)
    % JACOBI_METHOD Iterative solver for linear systems Ax = b
    
    if nargin < 1, A = []; end
    if nargin < 2, b = []; end
    if nargin < 3, x0 = []; end
    if nargin < 4, tol = []; end
    if nargin < 5, max_iters = []; end
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
