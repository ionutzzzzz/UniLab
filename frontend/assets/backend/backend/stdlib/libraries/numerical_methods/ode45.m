function [t_out, y_out] = ode45(f, tspan, y0)
    if nargin < 1, f = []; end
    if nargin < 2, tspan = []; end
    if nargin < 3, y0 = []; end
    t0 = tspan(1);
    tf = tspan(length(tspan));
    h = (tf - t0) / 100;
    t = t0;
    y = y0;
    
    % Initialize outputs
    n = length(y0);
    t_out = zeros(101, 1);
    y_out = zeros(101, n);
    
    t_out(1) = t;
    % Simple assignment for now
    for j = 1:n
        y_out(1, j) = y(j);
    end
    
    for i = 1:100
        k1 = f(t, y);
        
        y2 = y + (h/2) * k1;
        k2 = f(t + h/2, y2);
        
        y3 = y + (h/2) * k2;
        k3 = f(t + h/2, y3);
        
        y4 = y + h * k3;
        k4 = f(t + h, y4);
        
        y = y + (h/6) * (k1 + 2*k2 + 2*k3 + k4);
        t = t + h;
        
        t_out(i+1) = t;
        for j = 1:n
            y_out(i+1, j) = y(j);
        end
    end
end
