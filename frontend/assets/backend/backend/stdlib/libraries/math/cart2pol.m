function [theta, r, z] = cart2pol(x, y, z_in)
    % CART2POL Transform Cartesian coordinates to polar or cylindrical
    if nargin < 1, x = []; end
    if nargin < 2, y = []; end
    if nargin < 3, z_in = []; end
    theta = atan2(y, x);
    r = sqrt(x.^2 + y.^2);
    if nargin > 2
        z = z_in;
    end
end
