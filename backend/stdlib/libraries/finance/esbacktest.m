function results = esbacktest(returns, es_forecast, var_forecast)
    % ESBACKTEST Expected Shortfall backtesting
    if nargin < 1, returns = []; end
    if nargin < 2, es_forecast = []; end
    if nargin < 3, var_forecast = []; end
    violations = returns < var_forecast;
    excess_loss = returns(violations) - es_forecast(violations);
    
    results = struct();
    results.MeanExcessLoss = mean(excess_loss);
    results.NumViolations = sum(violations);
end
