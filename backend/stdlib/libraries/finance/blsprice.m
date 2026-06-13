function [call, put] = blsprice(S, K, T, r, sigma)
    % BLSPRICE Black-Scholes option pricing
    if nargin < 1, S = []; end
    if nargin < 2, K = []; end
    if nargin < 3, T = []; end
    if nargin < 4, r = []; end
    if nargin < 5, sigma = []; end
    call = black_scholes_call(S, K, T, r, sigma);
    put = black_scholes_put(S, K, T, r, sigma);
end
