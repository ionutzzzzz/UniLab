function price = asianbybls(S, K, T, r, sigma, type)
    % ASIANBYBLS Price of an Asian option using Turnbull-Wakeman approximation
    % Simplified: Using adjusted volatility for arithmetic average
    sigma_adj = sigma * sqrt((2 * 1 + 1) / (6 * (1 + 1))); % Very rough approx
    if strcmp(type, 'call')
        price = black_scholes_call(S, K, T, r, sigma_adj);
    else
        price = black_scholes_put(S, K, T, r, sigma_adj);
    end
end
