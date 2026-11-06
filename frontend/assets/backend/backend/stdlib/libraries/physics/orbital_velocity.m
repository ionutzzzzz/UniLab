function v = orbital_velocity(G, M, r)
    if nargin < 1, G = []; end
    if nargin < 2, M = []; end
    if nargin < 3, r = []; end
    v = sqrt(G * M / r);
end
