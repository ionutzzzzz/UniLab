function [call, put] = black_scholes(S, K, T, r, sigma)
    % BLACK_SCHOLES Option pricing model
    % S: Spot price, K: Strike price, T: Time to maturity, r: Risk-free rate, sigma: Volatility
    
    if nargin < 1, S = []; end
    if nargin < 2, K = []; end
    if nargin < 3, T = []; end
    if nargin < 4, r = []; end
    if nargin < 5, sigma = []; end
    d1 = (log(S / K) + (r + sigma^2 / 2) * T) / (sigma * sqrt(T));
    d2 = d1 - sigma * sqrt(T);
    
    % N(d) approximation using erf
    Nd1 = 0.5 * (1 + erf_approx(d1 / sqrt(2)));
    Nd2 = 0.5 * (1 + erf_approx(d2 / sqrt(2)));
    N_md1 = 0.5 * (1 + erf_approx(-d1 / sqrt(2)));
    N_md2 = 0.5 * (1 + erf_approx(-d2 / sqrt(2)));
    
    call = S * Nd1 - K * exp(-r * T) * Nd2;
    put = K * exp(-r * T) * N_md2 - S * N_md1;
end
