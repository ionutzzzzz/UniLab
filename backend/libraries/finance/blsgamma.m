function g = blsgamma(S, K, T, r, sigma)
    % BLSGAMMA Option gamma wrapper
    g = black_scholes_gamma(S, K, T, r, sigma);
end
