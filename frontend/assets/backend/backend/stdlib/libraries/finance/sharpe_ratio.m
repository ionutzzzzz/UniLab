function s = sharpe_ratio(returns, risk_free_rate)
    s = (mean(returns) - risk_free_rate) / std(returns);
end