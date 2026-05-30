function [log_priors, log_likelihoods, classes] = multinomial_naive_bayes_train(X, y, alpha)
    % MULTINOMIAL_NAIVE_BAYES_TRAIN Train a Multinomial Naive Bayes classifier
    % Useful for discrete counts (e.g., text classification)
    % alpha is the smoothing parameter (Laplace smoothing if alpha=1)
    
    if nargin < 3, alpha = 1; end
    
    [m, n] = size(X);
    classes = unique(y);
    num_classes = length(classes);
    
    log_priors = zeros(num_classes, 1);
    log_likelihoods = zeros(num_classes, n);
    
    for i = 1:num_classes
        c = classes(i);
        X_c = X(y == c, :);
        
        % Prior P(c)
        log_priors(i) = log(size(X_c, 1) / m);
        
        % Likelihood P(x|c) with smoothing
        total_word_count_c = sum(sum(X_c));
        word_counts_c = sum(X_c, 1);
        
        log_likelihoods(i, :) = log((word_counts_c + alpha) / (total_word_count_c + alpha * n));
    end
end
