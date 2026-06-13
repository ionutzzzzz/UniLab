function v = cylinder_volume(r, h)
    if nargin < 1, r = []; end
    if nargin < 2, h = []; end
    v = pi() * r^2 * h;
end