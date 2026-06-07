function t = black_scholes_theta(S, K, T, r, sigma, type)
    % BLACK_SCHOLES_THETA Option theta
    if nargin < 6, type = 'call'; end
    d1 = (log(S / K) + (r + sigma^2 / 2) * T) / (sigma * sqrt(T));
    d2 = d1 - sigma * sqrt(T);
    
    term1 = -(S * normpdf(d1) * sigma) / (2 * sqrt(T));
    if strcmp(type, 'call')
        t = term1 - r * K * exp(-r * T) * normcdf(d2);
    else
        t = term1 + r * K * exp(-r * T) * normcdf(-d2);
    end
end
