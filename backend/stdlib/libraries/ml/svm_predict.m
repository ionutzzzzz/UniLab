function [y_pred] = svm_predict(X, w, b)
    % SVM_PREDICT Predict using linear SVM
    
    if nargin < 1, X = []; end
    if nargin < 2, w = []; end
    if nargin < 3, b = []; end
    m = size(X, 1);
    y_pred = zeros(m, 1);
    
    for i = 1:m
        decision = sum(X(i, :) .* w) + b;
        if decision >= 0
            y_pred(i) = 1;
        else
            y_pred(i) = -1;
        end
    end
end
