function v = vis_viva_equation(mu, r, a)
    % VIS_VIVA_EQUATION Orbital speed at distance r
    % v^2 = mu * (2/r - 1/a)
    if nargin < 1, mu = []; end
    if nargin < 2, r = []; end
    if nargin < 3, a = []; end
    v = sqrt(mu * (2/r - 1/a));
end
