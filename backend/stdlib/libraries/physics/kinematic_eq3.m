function v2 = kinematic_eq3(v0, a, dx)
    if nargin < 1, v0 = []; end
    if nargin < 2, a = []; end
    if nargin < 3, dx = []; end
    v2 = v0^2 + 2 * a * dx;
end
