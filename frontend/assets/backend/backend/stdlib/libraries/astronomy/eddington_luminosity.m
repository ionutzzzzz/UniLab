function L_edd = eddington_luminosity(M)
    % EDDINGTON_LUMINOSITY Maximum luminosity of a star
    % L_edd approx 1.26e31 * (M / M_sun) Watts
    if nargin < 1, M = []; end
    L_edd = 3.2e4 * M * 3.828e26 / 1.989e30; % Simplified
end
