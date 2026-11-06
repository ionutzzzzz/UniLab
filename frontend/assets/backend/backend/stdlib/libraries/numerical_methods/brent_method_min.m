function [x_min] = brent_method_min(f, a, b, tol)
    % BRENT_METHOD_MIN Robust 1D minimization
    % Implementation of Brent's algorithm for minimization
    if nargin < 1, f = []; end
    if nargin < 2, a = []; end
    if nargin < 3, b = []; end
    if nargin < 4, tol = []; end
    phi = (3 - sqrt(5)) / 2;
    x = a + phi * (b - a);
    w = x; v = x;
    fw = unilab_call(f, x); fv = fw; fx = fw;
    d = 0; e = 0;
    
    for i = 1:100
        m = (a + b) / 2;
        if abs(x - m) <= 2*tol - (b - a)/2, break; end
        
        p = 0; q = 0; r = 0;
        if abs(e) > tol
            r = (x - w) * (fx - fv);
            q = (x - v) * (fx - fw);
            p = (x - v) * q - (x - w) * r;
            q = 2 * (q - r);
            if q > 0, p = -p; end
            q = abs(q);
            if abs(p) < abs(0.5 * q * e) && p > q*(a-x) && p < q*(b-x)
                e = d; d = p / q;
            else
                if x < m, e = b - x; else, e = a - x; end
                d = phi * e;
            end
        else
            if x < m, e = b - x; else, e = a - x; end
            d = phi * e;
        end
        
        u = x + d;
        fu = unilab_call(f, u);
        if fu <= fx
            if u < x, b = x; else, a = x; end
            v = w; fv = fw; w = x; fw = fx; x = u; fx = fu;
        else
            if u < x, a = u; else, b = u; end
            if fu <= fw || w == x
                v = w; fv = fw; w = u; fw = fu;
            elseif fu <= fv || v == x || v == w
                v = u; fv = fu;
            end
        end
    end
    x_min = x;
end
