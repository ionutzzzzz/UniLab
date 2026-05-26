function [theta] = linear_regression_train(X, y, alpha, num_iters)
    % LINEAR_REGRESSION_TRAIN Train linear regression using gradient descent
    % [theta] = linear_regression_train(X, y, alpha, num_iters)
    
    if nargin < 4, num_iters = 1000; end
    if nargin < 3, alpha = 0.01; end
    
    [m, n] = size(X);
    X = [ones(m, 1), X]; % Add bias term
    theta = zeros(n + 1, 1);
    
    for i = 1:num_iters
        h = X * theta;
        error = h - y;
        gradient = (X' * error) ./ m;
        theta = theta - alpha .* gradient;
    end
end
