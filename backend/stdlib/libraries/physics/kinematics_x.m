function x = kinematics_x(x0, v0, a, t)
    if nargin < 1, x0 = []; end
    if nargin < 2, v0 = []; end
    if nargin < 3, a = []; end
    if nargin < 4, t = []; end
    x = x0 + v0 * t + 0.5 * a * t^2;
end