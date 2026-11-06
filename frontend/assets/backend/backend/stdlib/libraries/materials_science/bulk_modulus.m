function K = bulk_modulus(E, nu)
    if nargin < 1, E = []; end
    if nargin < 2, nu = []; end
    K = E / (3 * (1 - 2 * nu));
end
