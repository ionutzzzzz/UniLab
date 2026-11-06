function v = blsvega(S, K, T, r, sigma)
    % BLSVEGA Option vega wrapper
    if nargin < 1, S = []; end
    if nargin < 2, K = []; end
    if nargin < 3, T = []; end
    if nargin < 4, r = []; end
    if nargin < 5, sigma = []; end
    v = black_scholes_vega(S, K, T, r, sigma);
end
