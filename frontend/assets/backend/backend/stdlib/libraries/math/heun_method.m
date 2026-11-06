function [y] = heun_method(f, t_span, y0, h)
    % HEUN_METHOD Solve ODE dy/dt = f(t, y) using Heun's method (improved Euler)
    % [y] = heun_method(f, t_span, y0, h)
    
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
        % Predictor
        y_pred = y(i, :) + h * k1;
        % Corrector
        k2 = unilab_call(f, t(i+1), y_pred);
        y(i+1, :) = y(i, :) + (h/2) * (k1 + k2);
    end
end
