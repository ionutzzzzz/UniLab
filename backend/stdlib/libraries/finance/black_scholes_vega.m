function v = black_scholes_vega(S, K, T, r, sigma)
    % BLACK_SCHOLES_VEGA Option vega
    d1 = (log(S / K) + (r + sigma^2 / 2) * T) / (sigma * sqrt(T));
    v = S * normpdf(d1) * sqrt(T);
end
