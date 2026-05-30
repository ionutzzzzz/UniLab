function [y] = sigmoid(x)
    % SIGMOID Calculate the sigmoid activation function
    % y = 1 / (1 + exp(-x))
    y = 1 ./ (1 + exp(-x));
end
