function v = black_scholes_vega(S, K, T, r, sigma)
    % BLACK_SCHOLES_VEGA Option vega
    if nargin < 1, S = []; end
    if nargin < 2, K = []; end
    if nargin < 3, T = []; end
    if nargin < 4, r = []; end
    if nargin < 5, sigma = []; end
    d1 = (log(S / K) + (r + sigma^2 / 2) * T) / (sigma * sqrt(T));
    v = S * normpdf(d1) * sqrt(T);
end
