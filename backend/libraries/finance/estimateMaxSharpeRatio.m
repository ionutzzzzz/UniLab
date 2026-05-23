function weights = estimateMaxSharpeRatio(obj)
    % ESTIMATEMAXSHARPERATIO Simplified optimization to find Max Sharpe Ratio weights
    
    if isempty(obj.AssetMean) || isempty(obj.AssetCovar)
        weights = [];
        return;
    end
    
    nAssets = length(obj.AssetMean);
    % Simplified mock optimization: picking the asset with highest return/std
    sharpe_ratios = obj.AssetMean(:) ./ sqrt(diag(obj.AssetCovar));
    [~, idx] = max(sharpe_ratios);
    
    weights = zeros(1, nAssets);
    weights(idx) = 1;
end
