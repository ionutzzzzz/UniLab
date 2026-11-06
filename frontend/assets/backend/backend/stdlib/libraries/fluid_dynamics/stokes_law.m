function Fd = stokes_law(mu, R, v)
    if nargin < 1, mu = []; end
    if nargin < 2, R = []; end
    if nargin < 3, v = []; end
    Fd = 6 * pi() * mu * R * v;
end
