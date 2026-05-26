function t = treynor_ratio(returns, risk_free_rate, beta)
    t = (mean(returns) - risk_free_rate) / beta;
end