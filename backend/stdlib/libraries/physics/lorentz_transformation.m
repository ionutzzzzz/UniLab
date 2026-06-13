function [t_prime, x_prime] = lorentz_transformation(t, x, v, c)
    % LORENTZ_TRANSFORMATION Transform coordinates between inertial frames
    % [t_prime, x_prime] = lorentz_transformation(t, x, v, c)
    
    if nargin < 1, t = []; end
    if nargin < 2, x = []; end
    if nargin < 3, v = []; end
    if nargin < 4, c = 299792458; end
    
    gamma = 1 / sqrt(1 - (v/c)^2);
    
    t_prime = gamma * (t - (v * x) / c^2);
    x_prime = gamma * (x - v * t);
end
