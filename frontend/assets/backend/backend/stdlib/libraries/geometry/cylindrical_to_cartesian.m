function [x, y, z] = cylindrical_to_cartesian(rho, phi, z)
    if nargin < 1, rho = []; end
    if nargin < 2, phi = []; end
    if nargin < 3, z = []; end
    x = rho * cos(phi);
    y = rho * sin(phi);
    % z remains z
end