function [boost_model] = adaboost_train(X, y, n_iters)
    % ADABOOST_TRAIN Train an AdaBoost classifier with decision stumps
    % y must be {-1, 1}
    
    if nargin < 1, X = []; end
    if nargin < 2, y = []; end
    if nargin < 3, n_iters = 50; end
    
    [m, n] = size(X);
    weights = ones(m, 1) / m;
    boost_model = cell(n_iters, 1);
    
    for i = 1:n_iters
        stump = decision_stump_train(X, y, weights);
        
        % Compute amount of say (alpha)
        % Avoid log(0)
        eps = 1e-15;
        alpha = 0.5 * log((1 - stump.error + eps) / (stump.error + eps));
        
        % Predict using stump
        preds = ones(m, 1);
        if stump.polarity == 1
            preds(X(:, stump.feature_idx) <= stump.threshold) = -1;
        else
            preds(X(:, stump.feature_idx) > stump.threshold) = -1;
        end
        
        % Update weights
        weights = weights .* exp(-alpha .* y .* preds);
        weights = weights / sum(weights);
        
        stump.alpha = alpha;
        boost_model{i} = stump;
    end
end
