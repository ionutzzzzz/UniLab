function d = blsdelta(S, K, T, r, sigma, type)
    % BLSDELTA Option delta wrapper
    if nargin < 1, S = []; end
    if nargin < 2, K = []; end
    if nargin < 3, T = []; end
    if nargin < 4, r = []; end
    if nargin < 5, sigma = []; end
    if nargin < 6, type = 'call'; end
    d = black_scholes_delta(S, K, T, r, sigma, type);
end
