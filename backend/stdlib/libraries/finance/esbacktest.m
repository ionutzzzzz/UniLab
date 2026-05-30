function results = esbacktest(returns, es_forecast, var_forecast)
    % ESBACKTEST Expected Shortfall backtesting
    violations = returns < var_forecast;
    excess_loss = returns(violations) - es_forecast(violations);
    
    results = struct();
    results.MeanExcessLoss = mean(excess_loss);
    results.NumViolations = sum(violations);
end
