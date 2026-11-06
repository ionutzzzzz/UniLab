function a = cylinder_surface_area(r, h)
    if nargin < 1, r = []; end
    if nargin < 2, h = []; end
    a = 2 * pi() * r * h + 2 * pi() * r^2;
end