function [y] = runge_kutta_4(f, t_span, y0, h)
    % RUNGE_KUTTA_4 Solve ODE dy/dt = f(t, y) using 4th order Runge-Kutta
    % [y] = runge_kutta_4(f, t_span, y0, h)
    
    if nargin < 1, f = []; end
    if nargin < 2, t_span = []; end
    if nargin < 3, y0 = []; end
    if nargin < 4, h = []; end
    t = t_span(1):h:t_span(2);
    n = length(t);
    y = zeros(n, length(y0));
    y(1, :) = y0;
    
    for i = 1:n-1
        k1 = unilab_call(f, t(i), y(i, :));
        k2 = unilab_call(f, t(i) + h/2, y(i, :) + h*k1/2);
        k3 = unilab_call(f, t(i) + h/2, y(i, :) + h*k2/2);
        k4 = unilab_call(f, t(i) + h, y(i, :) + h*k3);
        
        y(i+1, :) = y(i, :) + (h/6) * (k1 + 2*k2 + 2*k3 + k4);
    end
end
