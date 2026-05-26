function [gbm_model] = gradient_boosting_train(X, y, n_estimators, lr, max_depth, task)
    % GRADIENT_BOOSTING_TRAIN Train a gradient boosting ensemble
    % gbm_model = gradient_boosting_train(X, y, n_estimators, lr, max_depth, task)
    
    if nargin < 6, task = 'regression'; end
    if nargin < 5, max_depth = 3; end
    if nargin < 4, lr = 0.1; end
    if nargin < 3, n_estimators = 100; end
    
    [m, n] = size(X);
    
    if strcmp(task, 'regression')
        init_pred = mean(y);
    else
        p = mean(y);
        init_pred = log(p / (1 - p + 1e-9));
    end
    
    curr_pred = ones(m, 1) * init_pred;
    trees = cell(n_estimators, 1);
    
    for i = 1:n_estimators
        if strcmp(task, 'regression')
            residual = y - curr_pred;
        else
            % log-odds to prob
            p = 1 ./ (1 + exp(-curr_pred));
            residual = y - p;
        end
        
        % Train regression tree on residuals
        tree = decision_tree_train(X, residual, max_depth, 2);
        trees{i} = tree;
        
        % Update predictions
        tree_preds = decision_tree_predict(X, tree);
        curr_pred = curr_pred + lr * tree_preds;
    end
    
    gbm_model = struct('trees', {trees}, 'init_pred', init_pred, 'lr', lr, 'task', task);
end
