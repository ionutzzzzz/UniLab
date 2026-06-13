function g = black_scholes_gamma(S, K, T, r, sigma)
    % BLACK_SCHOLES_GAMMA Option gamma
    if nargin < 1, S = []; end
    if nargin < 2, K = []; end
    if nargin < 3, T = []; end
    if nargin < 4, r = []; end
    if nargin < 5, sigma = []; end
    d1 = (log(S / K) + (r + sigma^2 / 2) * T) / (sigma * sqrt(T));
    g = normpdf(d1) / (S * sigma * sqrt(T));
end
