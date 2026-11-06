function B = ampere_law_simple(I, r, mu0)
    % AMPERE_LAW_SIMPLE Magnetic field of a long straight wire
    % B = (mu0 * I) / (2 * pi * r)
    if nargin < 1, I = []; end
    if nargin < 2, r = []; end
    if nargin < 3, mu0 = 4 * pi() * 1e-7; end
    B = (mu0 * I) / (2 * pi() * r);
end
