function G = gibbs_free_energy(H, T, S)
    % GIBBS_FREE_ENERGY Calculate Gibbs free energy
    % G = H - T * S
    if nargin < 1, H = []; end
    if nargin < 2, T = []; end
    if nargin < 3, S = []; end
    G = H - T * S;
end
