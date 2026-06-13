function L = luminosity_star(R, T, sigma)
    if nargin < 1, R = []; end
    if nargin < 2, T = []; end
    if nargin < 3, sigma = []; end
    L = 4 * pi() * R^2 * sigma * T^4;
end
