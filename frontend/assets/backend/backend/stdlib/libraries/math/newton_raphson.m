function x = newton_raphson(f, df, x0, tol, max_iter)
    % NEWTON_RAPHSON Newton-Raphson root finding
    x = x0;
    for i = 1:max_iter
        fx = f(x);
        if abs(fx) < tol
            return;
        end
        dfx = df(x);
        if dfx == 0
            return;
        end
        x = x - fx / dfx;
    end
end
