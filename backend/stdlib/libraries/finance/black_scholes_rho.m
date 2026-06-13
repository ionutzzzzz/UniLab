function rho = black_scholes_rho(S, K, T, r, sigma, type)
    % BLACK_SCHOLES_RHO Option rho
    if nargin < 1, S = []; end
    if nargin < 2, K = []; end
    if nargin < 3, T = []; end
    if nargin < 4, r = []; end
    if nargin < 5, sigma = []; end
    if nargin < 6, type = 'call'; end
    d1 = (log(S / K) + (r + sigma^2 / 2) * T) / (sigma * sqrt(T));
    d2 = d1 - sigma * sqrt(T);
    
    if strcmp(type, 'call')
        rho = K * T * exp(-r * T) * normcdf(d2);
    else
        rho = -K * T * exp(-r * T) * normcdf(-d2);
    end
end
