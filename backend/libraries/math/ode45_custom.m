function [t, y] = ode45_custom(f, t_span, y0, tol)
    % ODE45_CUSTOM Solve ODE dy/dt = f(t, y)
    
    num_steps = 2000;
    t = linspace(t_span(1), t_span(2), num_steps + 1);
    h = t(2) - t(1);
    
    y = zeros(num_steps + 1, length(y0));
    y(1, :) = y0;
    
    for i = 1:num_steps
        % Runge-Kutta 4th order
        k1 = f(t(i), y(i, :));
        k1 = k1(:)';
        
        k2 = f(t(i) + h/2, y(i, :) + h*k1/2);
        k2 = k2(:)';
        
        k3 = f(t(i) + h/2, y(i, :) + h*k2/2);
        k3 = k3(:)';
        
        k4 = f(t(i) + h, y(i, :) + h*k3);
        k4 = k4(:)';
        
        y(i+1, :) = y(i, :) + (h/6) * (k1 + 2*k2 + 2*k3 + k4);
    end
end
