function v = de_broglie_velocity(lambda, m, h)
    % DE_BROGLIE_VELOCITY Velocity from de Broglie wavelength
    % v = h / (m * lambda)
    if nargin < 1, lambda = []; end
    if nargin < 2, m = []; end
    if nargin < 3, h = 6.62607015e-34; end
    v = h / (m * lambda);
end
