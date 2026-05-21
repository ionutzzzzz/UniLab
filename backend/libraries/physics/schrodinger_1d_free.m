function psi = schrodinger_1d_free(A, k, x, omega, t)
    psi = A * exp(1j * (k * x - omega * t));
end