function [y_pred] = random_forest_predict(X, forest)
    % RANDOM_FOREST_PREDICT Predict using a random forest
    
    if nargin < 1, X = []; end
    if nargin < 2, forest = []; end
    n_trees = length(forest);
    m = size(X, 1);
    votes = zeros(m, n_trees);
    
    for i = 1:n_trees
        tree = forest{i};
        votes(:, i) = decision_tree_predict(X, tree);
    end
    
    % Majority vote
    y_pred = zeros(m, 1);
    for j = 1:m
        y_pred(j) = mode(votes(j, :));
    end
end
