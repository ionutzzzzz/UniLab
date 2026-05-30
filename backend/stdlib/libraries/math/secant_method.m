function x = secant_method(f, x0, x1, tol)
    % SECANT_METHOD Secant method
    while abs(x1 - x0) > tol
        fx1 = f(x1);
        fx0 = f(x0);
        if fx1 == fx0
            break;
        end
        x_new = x1 - fx1 * (x1 - x0) / (fx1 - fx0);
        x0 = x1;
        x1 = x_new;
    end
    x = x1;
end
