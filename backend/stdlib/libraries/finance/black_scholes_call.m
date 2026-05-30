function call = black_scholes_call(S, K, T, r, sigma)
    d1 = (log(S / K) + (r + sigma^2 / 2) * T) / (sigma * sqrt(T));
    d2 = d1 - sigma * sqrt(T);
    call = S * normcdf(d1) - K * exp(-r * T) * normcdf(d2);
end