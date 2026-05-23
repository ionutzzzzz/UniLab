function d = blsdelta(S, K, T, r, sigma, type)
    % BLSDELTA Option delta wrapper
    if nargin < 6, type = 'call'; end
    d = black_scholes_delta(S, K, T, r, sigma, type);
end
