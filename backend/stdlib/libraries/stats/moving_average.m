function [y] = moving_average(x, window)
    % Calculates the moving average of a signal x with a given window size
    % Implementation using a simple sliding window
    n = length(x);
    y = zeros(size(x));
    
    for i = 1:n
        start_idx = max(1, i - floor(window/2));
        end_idx = min(n, i + floor(window/2));
        % Subsetting and mean
        subset = x(start_idx:end_idx);
        y(i) = mean(subset);
    end
end
