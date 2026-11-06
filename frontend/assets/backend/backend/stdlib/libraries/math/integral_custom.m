function [I] = integral_custom(f, a, b, tol)
    % INTEGRAL_CUSTOM Adaptive Simpson's numerical integration
    % I = integral_custom(f, a, b)
    
    if nargin < 1, f = []; end
    if nargin < 2, a = []; end
    if nargin < 3, b = []; end
    if nargin < 4, tol = 1e-6; end
    
    % Helper for recursive adaptive Simpson
    function [S] = adaptive_simpson(f, a, b, tol, whole)
    if nargin < 1, f = []; end
    if nargin < 2, a = []; end
    if nargin < 3, b = []; end
    if nargin < 4, tol = []; end
    if nargin < 5, whole = []; end
        c = (a + b) / 2;
        left = (a + c) / 2;
        right = (c + b) / 2;
        
        fa = unilab_call(f, a);
        fb = unilab_call(f, b);
        fc = unilab_call(f, c);
        fl = unilab_call(f, left);
        fr = unilab_call(f, right);
        
        Sleft = (c - a) / 6 * (fa + 4*fl + fc);
        Sright = (b - c) / 6 * (fc + 4*fr + fb);
        
        if abs(Sleft + Sright - whole) <= 15 * tol
            S = Sleft + Sright + (Sleft + Sright - whole) / 15;
        else
            S = adaptive_simpson(f, a, c, tol/2, Sleft) + ...
                adaptive_simpson(f, c, b, tol/2, Sright);
        end
    end
    
    fa = unilab_call(f, a);
    fb = unilab_call(f, b);
    fc = unilab_call(f, (a+b)/2);
    whole = (b - a) / 6 * (fa + 4*fc + fb);
    
    I = adaptive_simpson(f, a, b, tol, whole);
end
