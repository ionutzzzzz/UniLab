function [z] = standardize(data)
    % Standardizes data to have mean 0 and std 1
    m = mean(data);
    s = std(data);
    z = (data - m) ./ s;
end
