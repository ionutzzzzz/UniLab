function a = regular_polygon_area(n, s)
    if nargin < 1, n = []; end
    if nargin < 2, s = []; end
    a = (n * s^2) / (4 * tan(pi()/n));
end