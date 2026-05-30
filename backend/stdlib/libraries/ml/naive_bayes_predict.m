function [y_pred] = naive_bayes_predict(X, means, vars, priors)
    % NAIVE_BAYES_PREDICT Predict using a Gaussian Naive Bayes classifier
    % [y_pred] = naive_bayes_predict(X, means, vars, priors)
    
    [m, n] = size(X);
    num_classes = length(priors);
    y_pred = zeros(m, 1);
    
    for i = 1:m
        posteriors = zeros(num_classes, 1);
        for c = 1:num_classes
            prior = log(priors(c));
            % Gaussian likelihood
            likelihood = -0.5 * sum(log(2 * pi() * vars(c, :)) + (X(i, :) - means(c, :)).^2 ./ vars(c, :));
            posteriors(c) = prior + likelihood;
        end
        y_pred(i) = argmax(posteriors);
    end
end
