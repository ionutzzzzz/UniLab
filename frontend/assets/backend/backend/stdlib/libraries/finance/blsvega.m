function v = blsvega(S, K, T, r, sigma)
    % BLSVEGA Option vega wrapper
    v = black_scholes_vega(S, K, T, r, sigma);
end
