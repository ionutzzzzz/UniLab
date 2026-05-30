function [sx, sy, sz] = pauli_matrices()
    % PAULI_MATRICES Return the three Pauli matrices
    sx = [0, 1; 1, 0];
    sy = [0, -1j; 1j, 0];
    sz = [1, 0; 0, -1];
end
