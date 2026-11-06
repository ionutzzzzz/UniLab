function v = cone_volume(r, h)
    if nargin < 1, r = []; end
    if nargin < 2, h = []; end
    v = (1/3) * pi() * r^2 * h;
end