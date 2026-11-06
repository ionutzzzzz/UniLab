function [rho, phi, z] = cartesian_to_cylindrical(x, y, z)
    if nargin < 1, x = []; end
    if nargin < 2, y = []; end
    if nargin < 3, z = []; end
    rho = sqrt(x^2 + y^2);
    phi = atan2(y, x);
    % z remains z
end