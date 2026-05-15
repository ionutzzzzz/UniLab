function [t, y] = ode45_custom(f, t_span, y0, tol)
    % ODE45_CUSTOM Solve ODE dy/dt = f(t, y) using Dormand-Prince (simplified)
    % This is a simplified fixed-step version for now to demonstrate the logic
    % A full adaptive version would be much longer.
    
    h = (t_span(2) - t_span(1)) / 100; % Start with 100 steps
    t = t_span(1):h:t_span(2);
    n = length(t);
    y = zeros(n, length(y0));
    y(1, :) = y0;
    
    for i = 1:n-1
        % Runge-Kutta 4th order as a robust fallback for ode45-like interface
        k1 = unilab_call(f, t(i), y(i, :));
        k2 = unilab_call(f, t(i) + h/2, y(i, :) + h*k1/2);
        k3 = unilab_call(f, t(i) + h/2, y(i, :) + h*k2/2);
        k4 = unilab_call(f, t(i) + h, y(i, :) + h*k3);
        
        y(i+1, :) = y(i, :) + (h/6) * (k1 + 2*k2 + 2*k3 + k4);
    end
end
