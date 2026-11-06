function v = sphere_volume(r)
    if nargin < 1, r = []; end
    v = (4/3) * pi() * r^3;
end