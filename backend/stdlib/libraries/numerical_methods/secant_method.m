function x = secant_method(f, x0, x1, tol, max_iter)
    % SECANT_METHOD Find root of f(x) = 0 using the secant method
    % x = secant_method(f, x0, x1, tol, max_iter)
    
    if nargin < 1, f = []; end
    if nargin < 2, x0 = []; end
    if nargin < 3, x1 = []; end
    if nargin < 4, tol = 1e-6; end
    if nargin < 5, max_iter = 100; end
    
    for i = 1:max_iter
        fx0 = unilab_call(f, x0);
        fx1 = unilab_call(f, x1);
        
        if abs(fx1 - fx0) < 1e-12
            break;
        end
        
        x_next = x1 - fx1 * (x1 - x0) / (fx1 - fx0);
        
        if abs(x_next - x1) < tol
            x = x_next;
            return;
        end
        
        x0 = x1;
        x1 = x_next;
    end
    x = x1;
end
