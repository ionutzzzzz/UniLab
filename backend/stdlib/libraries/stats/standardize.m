function [z] = standardize(data)
    % Standardizes data to have mean 0 and std 1
    if nargin < 1, data = []; end
    m = mean(data);
    s = std(data);
    z = (data - m) ./ s;
end
