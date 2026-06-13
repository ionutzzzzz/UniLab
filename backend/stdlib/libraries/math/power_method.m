function [v, lambda] = power_method(A, x0, tol, max_iters)
    % POWER_METHOD Find the dominant eigenvalue and eigenvector of A
    
    if nargin < 1, A = []; end
    if nargin < 2, x0 = []; end
    if nargin < 3, tol = []; end
    if nargin < 4, max_iters = []; end
    v = x0(:);
    for i = 1:max_iters
        v_next = A * v;
        v_next = v_next / norm(v_next);
        
        if norm(v_next - v) < tol
            v = v_next;
            break;
        end
        v = v_next;
    end
    
    % Rayleigh quotient
    lambda = (v' * A * v) / (v' * v);
end
