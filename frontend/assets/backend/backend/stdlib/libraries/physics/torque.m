function t = torque(r, F, theta)
    if nargin < 1, r = []; end
    if nargin < 2, F = []; end
    if nargin < 3, theta = []; end
    t = r * F * sin(theta);
end
