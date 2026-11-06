function ac = centripetal_accel(v, r)
    if nargin < 1, v = []; end
    if nargin < 2, r = []; end
    ac = v^2 / r;
end
