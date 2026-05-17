function [tree] = decision_tree_train(X, y, max_depth, min_samples_split)
    % DECISION_TREE_TRAIN Train a simple classification decision tree (CART)
    % tree = decision_tree_train(X, y, max_depth, min_samples_split)
    
    if nargin < 3, max_depth = 5; end
    if nargin < 4, min_samples_split = 2; end
    
    [m, n] = size(X);
    unique_classes = unique(y);
    
    % Base case: all samples same class or max depth reached or too few samples
    if length(unique_classes) == 1 || max_depth == 0 || m < min_samples_split
        tree = struct('is_leaf', 1, 'class', mode(y));
        return;
    end
    
    % Find best split
    best_gini = 1e9;
    best_feature = 0;
    best_threshold = 0;
    
    for feature_idx = 1:n
        thresholds = unique(X(:, feature_idx));
        for i = 1:length(thresholds)
            threshold = thresholds(i);
            
            left_mask = X(:, feature_idx) <= threshold;
            right_mask = ~left_mask;
            
            if sum(left_mask) == 0 || sum(right_mask) == 0
                continue;
            end
            
            % Gini Impurity
            y_left = y(left_mask);
            y_right = y(right_mask);
            
            gini_left = 1 - sum((histcounts(y_left, unique_classes) / length(y_left)).^2);
            gini_right = 1 - sum((histcounts(y_right, unique_classes) / length(y_right)).^2);
            
            weighted_gini = (length(y_left)/m)*gini_left + (length(y_right)/m)*gini_right;
            
            if weighted_gini < best_gini
                best_gini = weighted_gini;
                best_feature = feature_idx;
                best_threshold = threshold;
            end
        end
    end
    
    if best_feature == 0
        tree = struct('is_leaf', 1, 'class', mode(y));
        return;
    end
    
    % Recursive split
    left_mask = X(:, best_feature) <= best_threshold;
    right_mask = ~left_mask;
    
    tree = struct('is_leaf', 0, ...
                  'feature_idx', best_feature, ...
                  'threshold', best_threshold, ...
                  'left', decision_tree_train(X(left_mask, :), y(left_mask), max_depth - 1, min_samples_split), ...
                  'right', decision_tree_train(X(right_mask, :), y(right_mask), max_depth - 1, min_samples_split));
end

function [counts] = histcounts(y, bins)
    counts = zeros(1, length(bins));
    for i = 1:length(bins)
        counts(i) = sum(y == bins(i));
    end
end
