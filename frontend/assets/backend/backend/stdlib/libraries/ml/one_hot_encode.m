function [Y] = one_hot_encode(y, num_classes)
    % ONE_HOT_ENCODE Convert labels to one-hot encoding
    % [Y] = one_hot_encode(y, num_classes)
    
    if nargin < 1, y = []; end
    if nargin < 2, num_classes = []; end
    m = length(y);
    Y = zeros(m, num_classes);
    for i = 1:m
        Y(i, y(i)) = 1;
    end
end
