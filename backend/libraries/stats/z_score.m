function [z] = z_score(data)
    % Calculates the z-score of each element in the data
    % z = (x - mean) / std
    m = mean(data);
    s = std(data);
    z = (data - m) ./ s;
end
