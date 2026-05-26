function rho = blsrho(S, K, T, r, sigma, type)
    % BLSRHO Option rho wrapper
    if nargin < 6, type = 'call'; end
    rho = black_scholes_rho(S, K, T, r, sigma, type);
end
