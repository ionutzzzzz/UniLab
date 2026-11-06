function U = gravitational_potential(G, M, m, r)
    if nargin < 1, G = []; end
    if nargin < 2, M = []; end
    if nargin < 3, m = []; end
    if nargin < 4, r = []; end
    U = - (G * M * m) / r;
end
