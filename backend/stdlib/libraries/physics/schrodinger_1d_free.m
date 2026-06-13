function psi = schrodinger_1d_free(A, k, x, omega, t)
    if nargin < 1, A = []; end
    if nargin < 2, k = []; end
    if nargin < 3, x = []; end
    if nargin < 4, omega = []; end
    if nargin < 5, t = []; end
    psi = A * exp(1j * (k * x - omega * t));
end