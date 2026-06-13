function R = hydrogen_radial_wavefunction(n, l, r, a0)
    % HYDROGEN_RADIAL_WAVEFUNCTION Radial wavefunction R_nl(r)
    if nargin < 1, n = []; end
    if nargin < 2, l = []; end
    if nargin < 3, r = []; end
    if nargin < 4, a0 = 5.291772109e-11; end
    rho = 2 * r / (n * a0);
    L = laguerre_poly_custom(n - l - 1, 2*l + 1, rho); % Associated Laguerre
    
    coeff = sqrt((2 / (n * a0))^3 * factorial_custom(n - l - 1) / (2 * n * factorial_custom(n + l)));
    R = coeff * exp(-rho / 2) * rho.^l .* L;
end

function L = laguerre_poly_custom(n, alpha, x)
    % Associated Laguerre polynomial L_n^alpha(x)
    if nargin < 1, n = []; end
    if nargin < 2, alpha = []; end
    if nargin < 3, x = []; end
    if n < 0, L = 0; return; end
    if n == 0, L = 1; return; end
    if n == 1, L = 1 + alpha - x; return; end
    
    L0 = 1; L1 = 1 + alpha - x;
    for k = 1:n-1
        L2 = ((2*k + 1 + alpha - x) .* L1 - (k + alpha) * L0) / (k + 1);
        L0 = L1; L1 = L2;
    end
    L = L1;
end
