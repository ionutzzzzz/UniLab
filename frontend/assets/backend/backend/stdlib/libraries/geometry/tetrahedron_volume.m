function v = tetrahedron_volume(a)
    if nargin < 1, a = []; end
    v = a^3 / (6 * sqrt(2));
end