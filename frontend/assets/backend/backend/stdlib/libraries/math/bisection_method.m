function [root] = bisection_method(f, a, b, tol, max_iters)
    % BISECTION_METHOD Find root of f(x) = 0 in the interval [a, b]
    
    if nargin < 1, f = []; end
    if nargin < 2, a = []; end
    if nargin < 3, b = []; end
    if nargin < 4, tol = 1e-6; end
    if nargin < 5, max_iters = 100; end
    
    fa = unilab_call(f, a);
    fb = unilab_call(f, b);
    
    if fa * fb >= 0
        disp('Error: f(a) and f(b) must have opposite signs.');
        root = [];
        return;
    end
    
    for i = 1:max_iters
        root = (a + b) / 2;
        f_mid = unilab_call(f, root);
        
        if abs(f_mid) < tol || (b - a) / 2 < tol
            return;
        end
        
        if f_mid * fa < 0
            b = root;
            fb = f_mid;
        else
            a = root;
            fa = f_mid;
        end
    end
end
