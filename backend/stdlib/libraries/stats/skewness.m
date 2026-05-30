function [s] = skewness(data)
    % Calculates the skewness of the data
    data = data(:);
    m = mean(data);
    v = var(data);
    n = length(data);
    
    s = mean((data - m) .^ 3) / (v ^ 1.5);
end
