function [theta] = logistic_regression_train(X, y, alpha, num_iters, lambda)
    % LOGISTIC_REGRESSION_TRAIN Train logistic regression using gradient descent
    % [theta] = logistic_regression_train(X, y, alpha, num_iters, lambda)
    
    if nargin < 5, lambda = 0; end
    if nargin < 4, num_iters = 1000; end
    if nargin < 3, alpha = 0.01; end
    
    [m, n] = size(X);
    X = [ones(m, 1), X]; % Add bias term
    theta = zeros(n + 1, 1);
    
    for i = 1:num_iters
        z = X * theta;
        h = sigmoid(z);
        error = h - y;
        
        % Gradient with L2 regularization (don't regularize bias)
        reg_term = (lambda / m) .* theta;
        reg_term(1) = 0;
        
        gradient = (X' * error) ./ m + reg_term;
        theta = theta - alpha .* gradient;
    end
end
