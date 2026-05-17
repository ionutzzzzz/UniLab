function [idx] = find_peaks(x, min_height)
    % FIND_PEAKS Find indices of local maxima
    if nargin < 2, min_height = -inf; end
    
    n = length(x);
    idx = [];
    
    for i = 2:n-1
        if x(i) > x(i-1) && x(i) > x(i+1) && x(i) >= min_height
            idx = [idx, i];
        end
    end
end
