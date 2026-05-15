function [X_train, X_test, y_train, y_test] = train_test_split(X, y, test_size)
    % TRAIN_TEST_SPLIT Split data into training and testing sets
    % [X_train, X_test, y_train, y_test] = train_test_split(X, y, test_size)
    
    n = size(X, 1);
    n_test = round(n * test_size);
    n_train = n - n_test;
    
    indices = randperm(n);
    
    train_idx = indices(1:n_train);
    test_idx = indices(n_train+1:end);
    
    X_train = X(train_idx, :);
    X_test = X(test_idx, :);
    y_train = y(train_idx, :);
    y_test = y(test_idx, :);
end
