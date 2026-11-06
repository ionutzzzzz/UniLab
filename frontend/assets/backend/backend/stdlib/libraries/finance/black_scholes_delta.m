function d = black_scholes_delta(S, K, T, r, sigma, type)
    % BLACK_SCHOLES_DELTA Option delta
    if nargin < 1, S = []; end
    if nargin < 2, K = []; end
    if nargin < 3, T = []; end
    if nargin < 4, r = []; end
    if nargin < 5, sigma = []; end
    if nargin < 6, type = 'call'; end
    d1 = (log(S / K) + (r + sigma^2 / 2) * T) / (sigma * sqrt(T));
    if strcmp(type, 'call')
        d = normcdf(d1);
    else
        d = normcdf(d1) - 1;
    end
end
