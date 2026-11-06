function rho = blsrho(S, K, T, r, sigma, type)
    % BLSRHO Option rho wrapper
    if nargin < 1, S = []; end
    if nargin < 2, K = []; end
    if nargin < 3, T = []; end
    if nargin < 4, r = []; end
    if nargin < 5, sigma = []; end
    if nargin < 6, type = 'call'; end
    rho = black_scholes_rho(S, K, T, r, sigma, type);
end
