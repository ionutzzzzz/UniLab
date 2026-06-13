function [y_pred] = multinomial_naive_bayes_predict(X, log_priors, log_likelihoods, classes)
    % MULTINOMIAL_NAIVE_BAYES_PREDICT Predict using Multinomial Naive Bayes
    
    if nargin < 1, X = []; end
    if nargin < 2, log_priors = []; end
    if nargin < 3, log_likelihoods = []; end
    if nargin < 4, classes = []; end
    [m, n] = size(X);
    num_classes = length(classes);
    y_pred = zeros(m, 1);
    
    for i = 1:m
        posteriors = zeros(num_classes, 1);
        for c = 1:num_classes
            % log P(c|x) approx log P(c) + sum(x_i * log P(x_i|c))
            posteriors(c) = log_priors(c) + sum(X(i, :) .* log_likelihoods(c, :));
        end
        y_pred(i) = classes(argmax(posteriors));
    end
end
