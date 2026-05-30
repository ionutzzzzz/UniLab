function plotFrontier(obj)
    % PLOTFRONTIER Mock - print values of frontier
    
    fprintf('Plotting Efficient Frontier for Portfolio...\n');
    if isempty(obj.AssetMean)
        fprintf('No assets defined in portfolio.\n');
        return;
    end
    
    weights = estimateFrontier(obj, 5);
    for i = 1:size(weights, 1)
        port_ret = weights(i, :) * obj.AssetMean(:);
        port_risk = sqrt(weights(i, :) * obj.AssetCovar * weights(i, :)');
        fprintf('Point %d: Return = %.4f, Risk = %.4f\n', i, port_ret, port_risk);
    end
end
