function v = torus_volume(R, r)
    if nargin < 1, R = []; end
    if nargin < 2, r = []; end
    v = (pi() * r^2) * (2 * pi() * R);
end