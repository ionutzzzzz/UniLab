function [y] = softmax(x)
    % SOFTMAX Calculate the softmax activation function
    % y = exp(x) / sum(exp(x))
    
    % Subtract max for numerical stability
    e_x = exp(x - max(x));
    y = e_x ./ sum(e_x, 1);
end
