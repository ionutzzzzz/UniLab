function a = torus_surface_area(R, r)
    if nargin < 1, R = []; end
    if nargin < 2, r = []; end
    a = (2 * pi() * r) * (2 * pi() * R);
end