function [r, theta, phi] = cartesian_to_spherical(x, y, z)
    r = sqrt(x^2 + y^2 + z^2);
    theta = acos(z / r);
    phi = atan2(y, x);
end