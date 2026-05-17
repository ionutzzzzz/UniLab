function [forest] = random_forest_train(X, y, n_trees, max_depth, min_samples_split, feature_subset_size)
    % RANDOM_FOREST_TRAIN Train a simple random forest classifier
    
    if nargin < 3, n_trees = 10; end
    if nargin < 4, max_depth = 5; end
    if nargin < 5, min_samples_split = 2; end
    if nargin < 6, feature_subset_size = floor(sqrt(size(X, 2))); end
    
    [m, n] = size(X);
    forest = cell(n_trees, 1);
    
    for i = 1:n_trees
        % Bootstrap sample (samples)
        indices = randi(m, m, 1);
        
        % Feature sampling
        feat_indices = randperm(n);
        feat_indices = feat_indices(1:feature_subset_size);
        
        X_sample = X(indices, feat_indices);
        y_sample = y(indices);
        
        % Train tree on subset of features
        tree = decision_tree_train(X_sample, y_sample, max_depth, min_samples_split);
        
        % Store which features were used in this tree
        tree.feat_indices = feat_indices;
        forest{i} = tree;
    end
end
