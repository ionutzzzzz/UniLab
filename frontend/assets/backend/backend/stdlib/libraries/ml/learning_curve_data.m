function [train_scores, test_scores] = learning_curve_data(X, y, train_sizes, model_type)
    % LEARNING_CURVE_DATA Generate data for a learning curve
    train_scores = zeros(length(train_sizes), 1);
    test_scores = zeros(length(train_sizes), 1);
    
    [X_train_full, X_test, y_train_full, y_test] = train_test_split(X, y, 0.2);
    
    for i = 1:length(train_sizes)
        m = train_sizes(i);
        X_sub = X_train_full(1:m, :);
        y_sub = y_train_full(1:m);
        
        % Simple linear regression for demonstration
        theta = linear_regression_train(X_sub, y_sub);
        
        y_train_pred = linear_regression_predict(X_sub, theta);
        y_test_pred = linear_regression_predict(X_test, theta);
        
        train_scores(i) = r2_score(y_sub, y_train_pred);
        test_scores(i) = r2_score(y_test, y_test_pred);
    end
end
