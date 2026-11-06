function G = shear_modulus(E, nu)
    if nargin < 1, E = []; end
    if nargin < 2, nu = []; end
    G = E / (2 * (1 + nu));
end
