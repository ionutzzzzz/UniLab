function F = coulombs_law(k, q1, q2, r)
    if nargin < 1, k = []; end
    if nargin < 2, q1 = []; end
    if nargin < 3, q2 = []; end
    if nargin < 4, r = []; end
    F = k * abs(q1 * q2) / r^2;
end