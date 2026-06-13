function dx = kinematic_eq2(v0, a, t)
    if nargin < 1, v0 = []; end
    if nargin < 2, a = []; end
    if nargin < 3, t = []; end
    dx = v0 * t + 0.5 * a * t^2;
end
