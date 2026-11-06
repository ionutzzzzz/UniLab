function v = kinematics_v(v0, a, t)
    if nargin < 1, v0 = []; end
    if nargin < 2, a = []; end
    if nargin < 3, t = []; end
    v = v0 + a * t;
end