function [pks, locs] = find_peaks(x, min_height)
    % FIND_PEAKS Find local maxima peaks and their indices
    if nargin < 1, x = []; end
    if nargin < 2, min_height = -inf; end
    
    n = length(x);
    locs = [];
    pks = [];
    
    for i = 2:(n-1)
        if x(i) > x(i-1) && x(i) > x(i+1) && x(i) >= min_height
            locs = [locs, i];
            pks = [pks, x(i)];
        end
    end
end
