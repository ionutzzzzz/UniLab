function [y_pred] = gradient_boosting_predict(X, gbm_model)
    % GRADIENT_BOOSTING_PREDICT Predict using gradient boosting ensemble
    
    if nargin < 1, X = []; end
    if nargin < 2, gbm_model = []; end
    m = size(X, 1);
    preds = ones(m, 1) * gbm_model.init_pred;
    
    n_trees = length(gbm_model.trees);
    for i = 1:n_trees
        tree_preds = decision_tree_predict(X, gbm_model.trees{i});
        preds = preds + gbm_model.lr * tree_preds;
    end
    
    if strcmp(gbm_model.task, 'regression')
        y_pred = preds;
    else
        y_pred = (1 ./ (1 + exp(-preds))) >= 0.5;
    end
end
