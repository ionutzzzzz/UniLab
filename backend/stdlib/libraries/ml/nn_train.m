function [W, b, loss_history] = nn_train(X, Y, epochs, lr, lambda, activation)
    % NN_TRAIN Train a simple neural network using gradient descent
    % [W, b, loss_history] = nn_train(X, Y, epochs, lr, lambda, activation)
    
    if nargin < 6, activation = 'sigmoid'; end
    if nargin < 5, lambda = 0; end
    if nargin < 4, lr = 0.01; end
    
    [m, n] = size(X);
    num_classes = size(Y, 2);
    
    % Initialization (He/Xavier style scaling)
    W = randn(n, num_classes) .* sqrt(2 / n);
    b = zeros(1, num_classes);
    loss_history = zeros(epochs, 1);
    
    for i = 1:epochs
        % Forward
        [A, Z] = nn_forward(X, W, b, activation);
        
        % Compute loss with L2 regularization
        reg_loss = (lambda / (2 * m)) * sum(W .^ 2);
        if strcmp(activation, 'softmax') || strcmp(activation, 'sigmoid')
            loss_history(i) = cross_entropy_loss(Y, A) + reg_loss;
        else
            loss_history(i) = mse(Y, A) + reg_loss;
        end
        
        % Backward
        [dW, db] = nn_backward(X, Y, A, Z, W, activation);
        
        % Add regularization gradient
        dW = dW + (lambda / m) * W;
        
        % Update
        W = W - lr * dW;
        b = b - lr * db;
    end
end
