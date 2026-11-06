function [r, theta, phi] = cartesian_to_spherical(x, y, z)
    if nargin < 1, x = []; end
    if nargin < 2, y = []; end
    if nargin < 3, z = []; end
    r = sqrt(x^2 + y^2 + z^2);
    theta = acos(z / r);
    phi = atan2(y, x);
end