function [x] = newton_raphson(f, df, x0, tol, max_iters)
    % NEWTON_RAPHSON Root finding using Newton-Raphson method
    % x_{n+1} = x_n - f(x_n) / f'(x_n)
    % f and df are function names (strings) or function handles
    
    x = x0;
    for i = 1:max_iters
        fx = unilab_call(f, x);
        dfx = unilab_call(df, x);
        
        if abs(dfx) < 1e-12
            break;
        end
        
        x_new = x - fx / dfx;
        
        if abs(x_new - x) < tol
            x = x_new;
            break;
        end
        x = x_new;
    end
end
