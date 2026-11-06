function K = rotational_kinetic_energy(I, omega)
    if nargin < 1, I = []; end
    if nargin < 2, omega = []; end
    K = 0.5 * I * omega^2;
end
