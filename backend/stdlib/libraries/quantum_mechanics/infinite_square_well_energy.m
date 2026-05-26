function E = infinite_square_well_energy(n, L, m, hbar)
    % INFINITE_SQUARE_WELL_ENERGY E_n = (n^2 * pi^2 * hbar^2) / (2 * m * L^2)
    if nargin < 4, hbar = 1; end
    E = (n^2 * pi()^2 * hbar^2) / (2 * m * L^2);
end
