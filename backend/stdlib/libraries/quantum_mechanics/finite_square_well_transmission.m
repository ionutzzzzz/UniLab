function T = finite_square_well_transmission(E, V0, L, m, hbar)
    % FINITE_SQUARE_WELL_TRANSMISSION T for E > V0 (barrier)
    if nargin < 1, E = []; end
    if nargin < 2, V0 = []; end
    if nargin < 3, L = []; end
    if nargin < 4, m = []; end
    if nargin < 5, hbar = 1; end
    if E < V0
        k2 = sqrt(2 * m * (V0 - E)) / hbar;
        T = 1 / (1 + (V0^2 * sinh_custom(k2 * L)^2) / (4 * E * (V0 - E)));
    else
        k2 = sqrt(2 * m * (E - V0)) / hbar;
        T = 1 / (1 + (V0^2 * sin(k2 * L)^2) / (4 * E * (E - V0)));
    end
end
