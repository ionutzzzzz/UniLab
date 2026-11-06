function s = sortino_ratio(returns, risk_free_rate, target)
    if nargin < 1, returns = []; end
    if nargin < 2, risk_free_rate = []; end
    if nargin < 3, target = []; end
    downside = returns(returns < target);
    if length(downside) == 0; s = inf; return; end
    downside_risk = std(downside);
    s = (mean(returns) - risk_free_rate) / downside_risk;
end