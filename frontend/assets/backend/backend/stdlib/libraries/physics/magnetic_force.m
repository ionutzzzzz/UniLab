function F = magnetic_force(q, v, B, theta)
    if nargin < 1, q = []; end
    if nargin < 2, v = []; end
    if nargin < 3, B = []; end
    if nargin < 4, theta = []; end
    F = q * v * B * sin(theta);
end