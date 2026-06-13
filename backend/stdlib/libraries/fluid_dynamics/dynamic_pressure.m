function q = dynamic_pressure(rho, v)
    if nargin < 1, rho = []; end
    if nargin < 2, v = []; end
    q = 0.5 * rho * v^2;
end
