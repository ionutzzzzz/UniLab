function x = newton_raphson(f, df, x0, tol, max_iter)
    % NEWTON_RAPHSON Newton-Raphson root finding
    if nargin < 1, f = []; end
    if nargin < 2, df = []; end
    if nargin < 3, x0 = []; end
    if nargin < 4, tol = []; end
    if nargin < 5, max_iter = []; end
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
