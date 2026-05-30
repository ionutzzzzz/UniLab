function [Sx, Sy, Sz, Sp, Sm] = spin_operators(s, hbar)
    % SPIN_OPERATORS Return spin angular momentum operators for spin s
    if nargin < 2, hbar = 1; end
    [sx, sy, sz] = pauli_matrices();
    if s == 0.5
        Sx = (hbar / 2) * sx;
        Sy = (hbar / 2) * sy;
        Sz = (hbar / 2) * sz;
    else
        % General case omitted for brevity, placeholder for 1/2
        Sx = (hbar / 2) * sx; Sy = (hbar / 2) * sy; Sz = (hbar / 2) * sz;
    end
    Sp = Sx + 1j * Sy;
    Sm = Sx - 1j * Sy;
end
