function E = quantum_harmonic_oscillator_energy(n, omega, hbar)
    % QUANTUM_HARMONIC_OSCILLATOR_ENERGY E_n = (n + 1/2) * hbar * omega
    if nargin < 1, n = []; end
    if nargin < 2, omega = []; end
    if nargin < 3, hbar = 1; end
    E = (n + 0.5) * hbar * omega;
end
