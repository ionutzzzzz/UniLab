function Fc = centripetal_force(m, v, r)
    if nargin < 1, m = []; end
    if nargin < 2, v = []; end
    if nargin < 3, r = []; end
    Fc = m * (v^2 / r);
end
