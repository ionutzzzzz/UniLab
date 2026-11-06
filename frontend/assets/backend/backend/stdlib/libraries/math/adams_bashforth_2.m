function [y] = adams_bashforth_2(f, t_span, y0, h)
    % ADAMS_BASHFORTH_2 Solve ODE dy/dt = f(t, y) using 2nd order Adams-Bashforth
    % [y] = adams_bashforth_2(f, t_span, y0, h)
    
    if nargin < 1, f = []; end
    if nargin < 2, t_span = []; end
    if nargin < 3, y0 = []; end
    if nargin < 4, h = []; end
    t = t_span(1):h:t_span(2);
    n = length(t);
    y = zeros(n, length(y0));
    y(1, :) = y0;
    
    % Use Euler for the second point to start
    k0 = unilab_call(f, t(1), y(1, :));
    y(2, :) = y(1, :) + h * k0;
    
    for i = 2:n-1
        k1 = unilab_call(f, t(i), y(i, :));
        k0 = unilab_call(f, t(i-1), y(i-1, :));
        y(i+1, :) = y(i, :) + (h/2) * (3*k1 - k0);
    end
end
