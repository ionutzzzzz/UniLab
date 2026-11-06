function [x] = brent_method_root(f, a, b, tol)
    % BRENT_METHOD_ROOT Robust root finding
    if nargin < 1, f = []; end
    if nargin < 2, a = []; end
    if nargin < 3, b = []; end
    if nargin < 4, tol = []; end
    fa = unilab_call(f, a);
    fb = unilab_call(f, b);
    if fa * fb > 0, error('f(a) and f(b) must have opposite signs'); end
    
    if abs(fa) < abs(fb), [a, b] = deal(b, a); [fa, fb] = deal(fb, fa); end
    c = a; fc = fa; d = 0; s = b; fs = fb;
    mflag = true;
    
    while abs(fs) > tol && abs(b - a) > tol
        if fa ~= fc && fb ~= fc
            % Inverse quadratic interpolation
            s = a*fb*fc/((fa-fb)*(fa-fc)) + b*fa*fc/((fb-fa)*(fb-fc)) + c*fa*fb/((fc-fa)*(fc-fb));
        else
            % Secant method
            s = b - fb * (b - a) / (fb - fa);
        end
        
        % Conditions to fall back to bisection
        if (s < (3*a + b)/4 || s > b) || ...
           (mflag && abs(s - b) >= abs(b - c)/2) || ...
           (~mflag && abs(s - b) >= abs(c - d)/2)
            s = (a + b) / 2;
            mflag = true;
        else
            mflag = false;
        end
        
        fs = unilab_call(f, s);
        d = c; c = b; fc = fb;
        if fa * fs < 0, b = s; fb = fs; else, a = s; fa = fs; end
        if abs(fa) < abs(fb), [a, b] = deal(b, a); [fa, fb] = deal(fb, fa); end
    end
    x = b;
end
