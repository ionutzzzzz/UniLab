function [y_pred] = knn_predict(X_train, y_train, X_test, K)
    % KNN_PREDICT K-Nearest Neighbors classification
    % [y_pred] = knn_predict(X_train, y_train, X_test, K)
    
    if nargin < 4, K = 3; end
    
    m_test = size(X_test, 1);
    m_train = size(X_train, 1);
    y_pred = zeros(m_test, 1);
    
    for i = 1:m_test
        % Calculate distances to all training points
        distances = sum((X_train - X_test(i, :)).^2, 2);
        
        % Find K nearest neighbors
        sorted_idx = argsort(distances);
        k_nearest_labels = y_train(sorted_idx(1:K));
        
        % Majority vote
        y_pred(i) = mode(k_nearest_labels);
    end
end
