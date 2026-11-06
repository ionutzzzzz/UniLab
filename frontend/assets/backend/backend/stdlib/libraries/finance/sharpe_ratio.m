function s = sharpe_ratio(returns, risk_free_rate)
    if nargin < 1, returns = []; end
    if nargin < 2, risk_free_rate = []; end
    s = (mean(returns) - risk_free_rate) / std(returns);
end