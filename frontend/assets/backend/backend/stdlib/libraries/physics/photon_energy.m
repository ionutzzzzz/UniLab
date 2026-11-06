function E = photon_energy(f, h)
    % PHOTON_ENERGY Energy of a photon
    % E = h * f
    if nargin < 1, f = []; end
    if nargin < 2, h = 6.62607015e-34; end
    E = h * f;
end
