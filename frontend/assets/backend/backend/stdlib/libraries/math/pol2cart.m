function [x, y, z] = pol2cart(theta, r, z_in)
    % POL2CART Transform polar or cylindrical coordinates to Cartesian
    if nargin < 1, theta = []; end
    if nargin < 2, r = []; end
    if nargin < 3, z_in = []; end
    x = r .* cos(theta);
    y = r .* sin(theta);
    if nargin > 2
        z = z_in;
    end
end
