function [x, y, z] = spherical_to_cartesian(r, theta, phi)
    if nargin < 1, r = []; end
    if nargin < 2, theta = []; end
    if nargin < 3, phi = []; end
    x = r * sin(theta) * cos(phi);
    y = r * sin(theta) * sin(phi);
    z = r * cos(theta);
end