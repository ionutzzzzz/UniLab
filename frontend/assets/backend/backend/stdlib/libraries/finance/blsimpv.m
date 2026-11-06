function iv = blsimpv(S, K, T, r, market_price, type)
    % BLSIMPV Implied volatility of an option
    if nargin < 1, S = []; end
    if nargin < 2, K = []; end
    if nargin < 3, T = []; end
    if nargin < 4, r = []; end
    if nargin < 5, market_price = []; end
    if nargin < 6, type = 'call'; end
    
    % Simple Newton-Raphson to find volatility
    iv = 0.2; % Initial guess
    for i = 1:20
        if strcmp(type, 'call')
            price = black_scholes_call(S, K, T, r, iv);
        else
            price = black_scholes_put(S, K, T, r, iv);
        end
        vega = black_scholes_vega(S, K, T, r, iv);
        
        diff = price - market_price;
        if abs(diff) < 1e-6, break; end
        
        iv = iv - diff / vega;
        if iv <= 0, iv = 1e-4; end
    end
end
