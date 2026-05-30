function [y_pred] = logistic_regression_predict(X, theta)
    % LOGISTIC_REGRESSION_PREDICT Predict using logistic regression
    % [y_pred] = logistic_regression_predict(X, theta)
    
    m = size(X, 1);
    X = [ones(m, 1), X]; % Add bias term
    z = X * theta;
    y_pred = sigmoid(z);
    
    % Convert to class labels
    y_pred = y_pred >= 0.5;
end
