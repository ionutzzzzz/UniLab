function [tree] = decision_tree_train(X, y, max_depth, min_samples_split, max_features, min_impurity_decrease)
    % DECISION_TREE_TRAIN Train a simple classification/regression tree
    % tree = decision_tree_train(X, y, max_depth, min_samples_split, max_features, min_impurity_decrease)
    
    if nargin < 6, min_impurity_decrease = 0; end
    if nargin < 5, max_features = size(X, 2); end
    if nargin < 4, min_samples_split = 2; end
    if nargin < 3, max_depth = 5; end
    
    [m, n] = size(X);
    unique_classes = unique(y);
    
    % Base case
    if length(unique_classes) == 1 || max_depth == 0 || m < min_samples_split
        tree = struct('is_leaf', 1, 'class', mode(y));
        return;
    end
    
    % Feature subsampling
    feat_indices = randperm(n);
    feat_indices = feat_indices(1:min(max_features, n));
    
    % Find best split
    best_gain = -1;
    best_feature = 0;
    best_threshold = 0;
    
    % Parent impurity
    if length(unique_classes) > 1 && all(floor(y) == y) % classification heuristic
        parent_impurity = 1 - sum((histcounts(y, unique_classes) / length(y)).^2);
        task = 'class';
    else
        parent_impurity = var(y);
        task = 'reg';
    end
    
    for feature_idx = feat_indices
        thresholds = unique(X(:, feature_idx));
        for i = 1:length(thresholds)
            threshold = thresholds(i);
            
            left_mask = X(:, feature_idx) <= threshold;
            right_mask = ~left_mask;
            
            if sum(left_mask) == 0 || sum(right_mask) == 0
                continue;
            end
            
            y_left = y(left_mask);
            y_right = y(right_mask);
            
            if strcmp(task, 'class')
                imp_left = 1 - sum((histcounts(y_left, unique_classes) / length(y_left)).^2);
                imp_right = 1 - sum((histcounts(y_right, unique_classes) / length(y_right)).^2);
            else
                imp_left = var(y_left);
                imp_right = var(y_right);
            end
            
            weighted_imp = (length(y_left)/m)*imp_left + (length(y_right)/m)*imp_right;
            gain = parent_impurity - weighted_imp;
            
            if gain > best_gain
                best_gain = gain;
                best_feature = feature_idx;
                best_threshold = threshold;
            end
        end
    end
    
    if best_feature == 0 || best_gain < min_impurity_decrease
        tree = struct('is_leaf', 1, 'class', mode(y));
        return;
    end
    
    % Recursive split
    left_mask = X(:, best_feature) <= best_threshold;
    right_mask = ~left_mask;
    
    tree = struct('is_leaf', 0, ...
                  'feature_idx', best_feature, ...
                  'threshold', best_threshold, ...
                  'left', decision_tree_train(X(left_mask, :), y(left_mask), max_depth - 1, min_samples_split, max_features, min_impurity_decrease), ...
                  'right', decision_tree_train(X(right_mask, :), y(right_mask), max_depth - 1, min_samples_split, max_features, min_impurity_decrease));
end

function [counts] = histcounts(y, bins)
    counts = zeros(1, length(bins));
    for i = 1:length(bins)
        counts(i) = sum(y == bins(i));
    end
end
