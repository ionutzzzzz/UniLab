function [x, y, z] = cylindrical_to_cartesian(rho, phi, z)
    x = rho * cos(phi);
    y = rho * sin(phi);
    % z remains z
end