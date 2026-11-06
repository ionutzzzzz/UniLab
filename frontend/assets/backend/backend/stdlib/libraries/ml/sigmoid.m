function [y] = sigmoid(x)
    % SIGMOID Calculate the sigmoid activation function
    % y = 1 / (1 + exp(-x))
    if nargin < 1, x = []; end
    y = 1 ./ (1 + exp(-x));
end
