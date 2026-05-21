function g = black_scholes_gamma(S, K, T, r, sigma)
    % BLACK_SCHOLES_GAMMA Option gamma
    d1 = (log(S / K) + (r + sigma^2 / 2) * T) / (sigma * sqrt(T));
    g = normpdf(d1) / (S * sigma * sqrt(T));
end
