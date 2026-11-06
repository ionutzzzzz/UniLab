function P = hydrostatic_pressure(rho, g, h)
    if nargin < 1, rho = []; end
    if nargin < 2, g = []; end
    if nargin < 3, h = []; end
    P = rho * g * h;
end
