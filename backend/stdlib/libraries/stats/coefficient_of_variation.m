function [cv] = coefficient_of_variation(data)
    % Calculates the coefficient of variation
    % CV = std / mean
    if nargin < 1, data = []; end
    cv = (std(data) / mean(data));
end
