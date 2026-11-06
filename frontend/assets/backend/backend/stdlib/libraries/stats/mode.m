function [m, f] = mode(x)
    % MODE Find most frequent values in an array
    
    if nargin < 1, x = []; end
    x = x(:);
    u = unique(x);
    counts = zeros(size(u));
    for i = 1:length(u)
        counts(i) = sum(x == u(i));
    end
    
    [f, idx] = max(counts);
    m = u(idx);
end
