function [y_pred] = linear_regression_predict(X, theta)
    % LINEAR_REGRESSION_PREDICT Predict using linear regression
    % [y_pred] = linear_regression_predict(X, theta)
    
    m = size(X, 1);
    X = [ones(m, 1), X]; % Add bias term
    y_pred = X * theta;
end
