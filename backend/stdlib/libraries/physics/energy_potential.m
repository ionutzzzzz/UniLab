function u = energy_potential(m, g, h)
    if nargin < 1, m = []; end
    if nargin < 2, g = []; end
    if nargin < 3, h = []; end
    u = m * g * h;
end