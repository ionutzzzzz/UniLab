function [theta] = ridge_regression_train(X, y, lambda)
    % RIDGE_REGRESSION_TRAIN Train linear regression with L2 regularization
    % Uses the closed-form solution: theta = (X'X + lambda*I)^-1 * X'y
    
    if nargin < 1, X = []; end
    if nargin < 2, y = []; end
    if nargin < 3, lambda = []; end
    [m, n] = size(X);
    X = [ones(m, 1), X]; % Add bias term
    n = n + 1;
    
    I = eye(n);
    I(1, 1) = 0; % Don't regularize bias
    
    theta = inv(X' * X + lambda * I) * X' * y;
end
