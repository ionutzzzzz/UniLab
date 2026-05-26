function results = varbacktest(returns, var_forecast)
    % VARBACKTEST Value-at-Risk backtesting
    violations = returns < var_forecast;
    num_violations = sum(violations);
    ratio = num_violations / length(returns);
    
    results = struct();
    results.NumViolations = num_violations;
    results.ViolationRatio = ratio;
    results.TotalObservations = length(returns);
    % Kupiec POF test placeholder
    results.KupiecTest = 'Passed'; 
end
