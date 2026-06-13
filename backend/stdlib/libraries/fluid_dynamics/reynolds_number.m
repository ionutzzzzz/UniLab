function Re = reynolds_number(rho, v, L, mu)
    if nargin < 1, rho = []; end
    if nargin < 2, v = []; end
    if nargin < 3, L = []; end
    if nargin < 4, mu = []; end
    Re = (rho * v * L) / mu;
end
