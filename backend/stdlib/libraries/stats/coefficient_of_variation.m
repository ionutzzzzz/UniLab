function [cv] = coefficient_of_variation(data)
    % Calculates the coefficient of variation
    % CV = std / mean
    cv = (std(data) / mean(data));
end
