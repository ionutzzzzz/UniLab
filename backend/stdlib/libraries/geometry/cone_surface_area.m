function a = cone_surface_area(r, l)
    if nargin < 1, r = []; end
    if nargin < 2, l = []; end
    a = pi() * r * l + pi() * r^2;
end