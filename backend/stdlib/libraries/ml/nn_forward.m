function [A, Z] = nn_forward(X, W, b, activation_func)
    % NN_FORWARD Neural network forward pass for one layer
    % [A, Z] = nn_forward(X, W, b, activation_func)
    
    Z = X * W + b';
    
    if strcmp(activation_func, 'sigmoid')
        A = sigmoid(Z);
    elseif strcmp(activation_func, 'relu')
        A = relu(Z);
    elseif strcmp(activation_func, 'softmax')
        A = softmax(Z);
    else
        A = Z; % Linear
    end
end
