function a = polygon_interior_angle(n)
    if nargin < 1, n = []; end
    a = (n - 2) * 180 / n;
end