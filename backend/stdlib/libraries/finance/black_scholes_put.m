function put = black_scholes_put(S, K, T, r, sigma)
    d1 = (log(S / K) + (r + sigma^2 / 2) * T) / (sigma * sqrt(T));
    d2 = d1 - sigma * sqrt(T);
    put = K * exp(-r * T) * normcdf(-d2) - S * normcdf(-d1);
end