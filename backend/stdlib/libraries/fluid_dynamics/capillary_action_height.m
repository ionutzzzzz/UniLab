function h = capillary_action_height(gamma, theta, rho, g, r)
    if nargin < 1, gamma = []; end
    if nargin < 2, theta = []; end
    if nargin < 3, rho = []; end
    if nargin < 4, g = []; end
    if nargin < 5, r = []; end
    h = (2 * gamma * cos(theta)) / (rho * g * r);
end
