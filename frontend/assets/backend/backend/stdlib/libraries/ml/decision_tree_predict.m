function [y_pred] = decision_tree_predict(X, tree)
    % DECISION_TREE_PREDICT Predict using a decision tree
    
    if nargin < 1, X = []; end
    if nargin < 2, tree = []; end
    m = size(X, 1);
    y_pred = zeros(m, 1);
    
    for i = 1:m
        y_pred(i) = traverse_tree(X(i, :), tree);
    end
end

function [class] = traverse_tree(x, node)
    if nargin < 1, x = []; end
    if nargin < 2, node = []; end
    if node.is_leaf == 1
        class = node.class;
        return;
    end
    
    if x(node.feature_idx) <= node.threshold
        class = traverse_tree(x, node.left);
    else
        class = traverse_tree(x, node.right);
    end
end
