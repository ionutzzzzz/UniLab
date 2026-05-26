function d = black_scholes_delta(S, K, T, r, sigma, type)
    % BLACK_SCHOLES_DELTA Option delta
    if nargin < 6, type = 'call'; end
    d1 = (log(S / K) + (r + sigma^2 / 2) * T) / (sigma * sqrt(T));
    if strcmp(type, 'call')
        d = normcdf(d1);
    else
        d = normcdf(d1) - 1;
    end
end
