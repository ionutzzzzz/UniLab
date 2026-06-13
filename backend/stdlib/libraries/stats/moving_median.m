function [y] = moving_median(x, window)
    % Calculates the moving median of a signal x with a given window size
    if nargin < 1, x = []; end
    if nargin < 2, window = []; end
    n = length(x);
    y = zeros(size(x));
    
    for i = 1:n
        start_idx = max(1, (i - floor(window/2)));
        end_idx = min(n, (i + floor(window/2)));
        subset = x(start_idx:end_idx);
        y(i) = median(subset);
    end
end
