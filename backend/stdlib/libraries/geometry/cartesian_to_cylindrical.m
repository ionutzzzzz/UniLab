function [rho, phi, z] = cartesian_to_cylindrical(x, y, z)
    rho = sqrt(x^2 + y^2);
    phi = atan2(y, x);
    % z remains z
end