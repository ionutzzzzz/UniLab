function [forest] = random_forest_train(X, y, n_trees, max_depth, min_samples_split, max_features, bootstrap)
    % RANDOM_FOREST_TRAIN Train a simple random forest classifier
    
    if nargin < 7, bootstrap = 1; end
    if nargin < 6, max_features = floor(sqrt(size(X, 2))); end
    if nargin < 5, min_samples_split = 2; end
    if nargin < 4, max_depth = 5; end
    if nargin < 3, n_trees = 10; end
    
    [m, n] = size(X);
    forest = cell(n_trees, 1);
    
    for i = 1:n_trees
        % Bootstrap sample
        if bootstrap
            indices = randi(m, m, 1);
        else
            indices = 1:m;
        end
        
        X_sample = X(indices, :);
        y_sample = y(indices);
        
        % Train tree (now decision_tree_train handles max_features internally)
        tree = decision_tree_train(X_sample, y_sample, max_depth, min_samples_split, max_features);
        forest{i} = tree;
    end
end
