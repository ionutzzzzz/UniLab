function t = treynor_ratio(returns, risk_free_rate, beta)
    if nargin < 1, returns = []; end
    if nargin < 2, risk_free_rate = []; end
    if nargin < 3, beta = []; end
    t = (mean(returns) - risk_free_rate) / beta;
end