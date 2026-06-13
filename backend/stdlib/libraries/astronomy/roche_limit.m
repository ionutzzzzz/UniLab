function d = roche_limit(R_primary, rho_primary, rho_satellite)
    % ROCHE_LIMIT Calculate the Roche limit distance
    % d = R_primary * (2 * rho_primary / rho_satellite)^(1/3)
    if nargin < 1, R_primary = []; end
    if nargin < 2, rho_primary = []; end
    if nargin < 3, rho_satellite = []; end
    d = R_primary * (2 * rho_primary / rho_satellite)^(1/3);
end
