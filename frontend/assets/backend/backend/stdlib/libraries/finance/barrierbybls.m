function price = barrierbybls(S, K, T, r, sigma, barrier, type)
    % BARRIERBYBLS Price of a Barrier option (simplified)
    % This is a placeholder for the full Reiner-Rubinstein formula
    if S > barrier && strcmp(type, 'call')
        price = 0; % Knock-out
    else
        price = black_scholes_call(S, K, T, r, sigma) * 0.8; % Mock adjustment
    end
end
