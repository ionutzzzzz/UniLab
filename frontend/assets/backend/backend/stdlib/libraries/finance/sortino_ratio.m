function s = sortino_ratio(returns, risk_free_rate, target)
    downside = returns(returns < target);
    if length(downside) == 0; s = inf; return; end
    downside_risk = std(downside);
    s = (mean(returns) - risk_free_rate) / downside_risk;
end