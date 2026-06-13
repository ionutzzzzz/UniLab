function f = force_gravity(G, m1, m2, r)
    if nargin < 1, G = []; end
    if nargin < 2, m1 = []; end
    if nargin < 3, m2 = []; end
    if nargin < 4, r = []; end
    f = G * m1 * m2 / r^2;
end