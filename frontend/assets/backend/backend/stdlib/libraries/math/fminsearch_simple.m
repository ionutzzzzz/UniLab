function [x_min, f_min] = fminsearch_simple(f, x0, tol, max_iters)
    % FMINSEARCH_SIMPLE Simple Nelder-Mead-like optimization for 1D/small dim
    
    if nargin < 1, f = []; end
    if nargin < 2, x0 = []; end
    if nargin < 3, tol = 1e-6; end
    if nargin < 4, max_iters = 200; end
    
    % This is a very simplified version for demonstration
    x = x0;
    h = 0.01;
    
    for i = 1:max_iters
        f_val = unilab_call(f, x);
        f_plus = unilab_call(f, x + h);
        f_minus = unilab_call(f, x - h);
        
        if f_plus < f_val && f_plus < f_minus
            x = x + h;
        elseif f_minus < f_val
            x = x - h;
        else
            h = h / 2;
        end
        
        if h < tol
            break;
        end
    end
    x_min = x;
    f_min = unilab_call(f, x_min);
end
