function t = blstheta(S, K, T, r, sigma, type)
    % BLSTHETA Option theta wrapper
    if nargin < 6, type = 'call'; end
    t = black_scholes_theta(S, K, T, r, sigma, type);
end
