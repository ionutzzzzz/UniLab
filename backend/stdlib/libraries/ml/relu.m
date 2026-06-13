function [y] = relu(x)
    % RELU Calculate the Rectified Linear Unit activation function
    % y = max(0, x)
    if nargin < 1, x = []; end
    y = max(0, x);
end
