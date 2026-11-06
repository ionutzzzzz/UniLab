function r_s = schwarzschild_radius(G, M, c)
    if nargin < 1, G = []; end
    if nargin < 2, M = []; end
    if nargin < 3, c = []; end
    r_s = (2 * G * M) / c^2;
end
