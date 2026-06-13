function v = ellipsoid_volume(a, b, c)
    if nargin < 1, a = []; end
    if nargin < 2, b = []; end
    if nargin < 3, c = []; end
    v = (4/3) * pi() * a * b * c;
end