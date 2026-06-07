function [y_pred] = knn_reg_predict(X_train, y_train, X_test, K)
    % KNN_REG_PREDICT K-Nearest Neighbors regression
    
    if nargin < 4, K = 3; end
    
    m_test = size(X_test, 1);
    y_pred = zeros(m_test, 1);
    
    for i = 1:m_test
        % Calculate distances
        distances = sum((X_train - X_test(i, :)).^2, 2);
        
        % Find K nearest neighbors
        sorted_idx = argsort(distances);
        k_nearest_vals = y_train(sorted_idx(1:K));
        
        % Average
        y_pred(i) = mean(k_nearest_vals);
    end
end
