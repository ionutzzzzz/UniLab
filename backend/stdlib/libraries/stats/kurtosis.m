function [k] = kurtosis(data)
    % Calculates the kurtosis of the data
    data = data(:);
    m = mean(data);
    v = var(data);
    
    k = mean((data - m) .^ 4) / (v ^ 2);
end
