function [call, put] = blsprice(S, K, T, r, sigma)
    % BLSPRICE Black-Scholes option pricing
    call = black_scholes_call(S, K, T, r, sigma);
    put = black_scholes_put(S, K, T, r, sigma);
end
