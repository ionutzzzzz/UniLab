function [w, b] = svm_train(X, y, lambda, epochs)
    % SVM_TRAIN Linear SVM using Pegasos algorithm
    % y must be encoded as {-1, 1}
    
    if nargin < 1, X = []; end
    if nargin < 2, y = []; end
    if nargin < 4, epochs = 1000; end
    if nargin < 3, lambda = 0.01; end
    
    [m, n] = size(X);
    w = zeros(1, n);
    b = 0;
    
    for t = 1:epochs
        eta = 1 / (lambda * t);
        for i = 1:m
            % Ensure decision is a scalar using sum and element-wise multiplication
            decision = y(i) * (sum(X(i, :) .* w) + b);
            if decision < 1
                w = (1 - eta * lambda) .* w + eta * y(i) .* X(i, :);
                b = b + eta * y(i);
            else
                w = (1 - eta * lambda) .* w;
            end
        end
    end
end
