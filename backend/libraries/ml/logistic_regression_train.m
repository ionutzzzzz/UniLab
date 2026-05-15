function [theta] = logistic_regression_train(X, y, alpha, num_iters)
    % LOGISTIC_REGRESSION_TRAIN Train logistic regression using gradient descent
    % [theta] = logistic_regression_train(X, y, alpha, num_iters)
    
    [m, n] = size(X);
    X = [ones(m, 1), X]; % Add bias term
    theta = zeros(n + 1, 1);
    
    for i = 1:num_iters
        z = X * theta;
        h = sigmoid(z);
        error = h - y;
        gradient = (X' * error) ./ m;
        theta = theta - alpha .* gradient;
    end
end
