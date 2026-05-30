function A = helmholtz_free_energy(U, T, S)
    % HELMHOLTZ_FREE_ENERGY Calculate Helmholtz free energy
    % A = U - T * S
    A = U - T * S;
end
