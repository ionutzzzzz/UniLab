function x = brent_method_root(f, a, b, tol)
    % BRENT_METHOD_ROOT Brent's root finding
    fa = f(a); fb = f(b);
    if fa * fb > 0
        error('Root must be bracketed');
    end
    if abs(fa) < abs(fb)
        [a, b] = deal(b, a);
        [fa, fb] = deal(fb, fa);
    end
    c = a; fc = fa; mflag = true;
    while fb ~= 0 && abs(b - a) > tol
        if fa ~= fc && fb ~= fc
            % Inverse quadratic interpolation
            s = a*fb*fc/((fa-fb)*(fa-fc)) + b*fa*fc/((fb-fa)*(fb-fc)) + c*fa*fb/((fc-fa)*(fc-fb));
        else
            % Secant method
            s = b - fb * (b - a) / (fb - fa);
        end
        % Conditions to use bisection instead
        if (s < (3*a+b)/4 || s > b) || ...
           (mflag && abs(s-b) >= abs(b-c)/2) || ...
           (~mflag && abs(s-b) >= abs(c-d)/2) || ...
           (mflag && abs(b-c) < tol) || ...
           (~mflag && abs(c-d) < tol)
            s = (a + b) / 2;
            mflag = true;
        else
            mflag = false;
        end
        fs = f(s); d = c; c = b; fc = fb;
        if fa * fs < 0
            b = s; fb = fs;
        else
            a = s; fa = fs;
        end
        if abs(fa) < abs(fb)
            [a, b] = deal(b, a);
            [fa, fb] = deal(fb, fa);
        end
    end
    x = b;
end
