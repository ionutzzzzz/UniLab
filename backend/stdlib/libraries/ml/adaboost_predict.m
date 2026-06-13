function [y_pred] = adaboost_predict(X, boost_model)
    % ADABOOST_PREDICT Predict using AdaBoost ensemble
    
    if nargin < 1, X = []; end
    if nargin < 2, boost_model = []; end
    m = size(X, 1);
    n_models = length(boost_model);
    total_preds = zeros(m, 1);
    
    for i = 1:n_models
        stump = boost_model{i};
        preds = ones(m, 1);
        if stump.polarity == 1
            preds(X(:, stump.feature_idx) <= stump.threshold) = -1;
        else
            preds(X(:, stump.feature_idx) > stump.threshold) = -1;
        end
        
        total_preds = total_preds + stump.alpha .* preds;
    end
    
    y_pred = sign(total_preds);
    y_pred(y_pred == 0) = 1;
end
