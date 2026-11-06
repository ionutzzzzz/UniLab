function k = energy_kinetic(m, v)
    if nargin < 1, m = []; end
    if nargin < 2, v = []; end
    k = 0.5 * m * v^2;
end