function [y_pred] = decision_tree_predict(X, tree)
    % DECISION_TREE_PREDICT Predict using a decision tree
    
    m = size(X, 1);
    y_pred = zeros(m, 1);
    
    for i = 1:m
        y_pred(i) = traverse_tree(X(i, :), tree);
    end
end

function [class] = traverse_tree(x, node)
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
