function d = bragg_law(n, lambda, theta)
    if nargin < 1, n = []; end
    if nargin < 2, lambda = []; end
    if nargin < 3, theta = []; end
    d = (n * lambda) / (2 * sin(theta));
end