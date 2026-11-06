function [dW, db] = nn_backward(X, Y, A, Z, W, activation_func)
    % NN_BACKWARD Neural network backward pass for a single layer
    % A is the output of the layer, Z is the pre-activation.
    
    if nargin < 1, X = []; end
    if nargin < 2, Y = []; end
    if nargin < 3, A = []; end
    if nargin < 4, Z = []; end
    if nargin < 5, W = []; end
    if nargin < 6, activation_func = []; end
    m = size(X, 1);
    
    % Derivative of activation
    if strcmp(activation_func, 'sigmoid')
        dZ = A - Y; % Assuming cross entropy loss with sigmoid
    elseif strcmp(activation_func, 'relu')
        dZ = (A - Y) .* (Z > 0);
    elseif strcmp(activation_func, 'softmax')
        dZ = A - Y; % Cross entropy with softmax
    else
        dZ = A - Y; % Linear / MSE
    end
    
    dW = (X' * dZ) / m;
    db = sum(dZ, 1) / m;
end
