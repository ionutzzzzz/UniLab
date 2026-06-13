function A = helmholtz_free_energy(U, T, S)
    % HELMHOLTZ_FREE_ENERGY Calculate Helmholtz free energy
    % A = U - T * S
    if nargin < 1, U = []; end
    if nargin < 2, T = []; end
    if nargin < 3, S = []; end
    A = U - T * S;
end
