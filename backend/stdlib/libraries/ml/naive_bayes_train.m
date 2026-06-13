function [means, vars, priors] = naive_bayes_train(X, y)
    % NAIVE_BAYES_TRAIN Train a Gaussian Naive Bayes classifier
    % [means, vars, priors] = naive_bayes_train(X, y)
    
    if nargin < 1, X = []; end
    if nargin < 2, y = []; end
    classes = unique(y);
    num_classes = length(classes);
    [m, n] = size(X);
    
    means = zeros(num_classes, n);
    vars = zeros(num_classes, n);
    priors = zeros(num_classes, 1);
    
    for i = 1:num_classes
        c = classes(i);
        X_c = X(y == c, :);
        means(i, :) = mean(X_c, 1);
        vars(i, :) = var(X_c, 0, 1);
        priors(i) = size(X_c, 1) / m;
    end
end
