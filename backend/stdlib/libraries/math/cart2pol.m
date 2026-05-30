function [theta, r, z] = cart2pol(x, y, z_in)
    % CART2POL Transform Cartesian coordinates to polar or cylindrical
    theta = atan2(y, x);
    r = sqrt(x.^2 + y.^2);
    if nargin > 2
        z = z_in;
    end
end
