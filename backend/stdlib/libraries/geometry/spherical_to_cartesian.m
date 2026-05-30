function [x, y, z] = spherical_to_cartesian(r, theta, phi)
    x = r * sin(theta) * cos(phi);
    y = r * sin(theta) * sin(phi);
    z = r * cos(theta);
end