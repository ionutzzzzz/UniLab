function [se] = std_error(data)
    % Calculates the standard error of the mean
    if nargin < 1, data = []; end
    n = length(data);
    s = std(data);
    se = s / sqrt(n);
end
