function [k] = kurtosis(data)
    % Calculates the kurtosis of the data
    if nargin < 1, data = []; end
    data = data(:);
    m = mean(data);
    v = var(data);
    
    k = mean((data - m) .^ 4) / (v ^ 2);
end
