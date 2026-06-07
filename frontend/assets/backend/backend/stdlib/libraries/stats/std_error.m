function [se] = std_error(data)
    % Calculates the standard error of the mean
    n = length(data);
    s = std(data);
    se = s / sqrt(n);
end
