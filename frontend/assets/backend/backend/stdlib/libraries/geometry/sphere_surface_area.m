function a = sphere_surface_area(r)
    if nargin < 1, r = []; end
    a = 4 * pi() * r^2;
end