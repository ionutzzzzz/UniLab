function [Y] = one_hot_encode(y, num_classes)
    % ONE_HOT_ENCODE Convert labels to one-hot encoding
    % [Y] = one_hot_encode(y, num_classes)
    
    m = length(y);
    Y = zeros(m, num_classes);
    for i = 1:m
        Y(i, y(i)) = 1;
    end
end
