function weights = estimateMinVariance(obj)
    % ESTIMATEMINVARIANCE Simplified optimization to minimize portfolio variance
    
    if isempty(obj.AssetCovar)
        weights = [];
        return;
    end
    
    nAssets = size(obj.AssetCovar, 1);
    % Simplified mock optimization: inverse variance weighting
    variances = diag(obj.AssetCovar);
    inv_vars = 1 ./ variances;
    weights = (inv_vars / sum(inv_vars))';
end
