function g = blsgamma(S, K, T, r, sigma)
    % BLSGAMMA Option gamma wrapper
    if nargin < 1, S = []; end
    if nargin < 2, K = []; end
    if nargin < 3, T = []; end
    if nargin < 4, r = []; end
    if nargin < 5, sigma = []; end
    g = black_scholes_gamma(S, K, T, r, sigma);
end
