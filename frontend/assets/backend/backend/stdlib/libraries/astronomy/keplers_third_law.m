function T = keplers_third_law(G, M, a)
    if nargin < 1, G = []; end
    if nargin < 2, M = []; end
    if nargin < 3, a = []; end
    T = sqrt((4 * pi()^2 * a^3) / (G * M));
end
