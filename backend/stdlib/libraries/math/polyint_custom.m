function [q] = polyint_custom(p, k)
    % POLYINT_CUSTOM Integrate polynomial p
    % [q] = polyint_custom(p, k) where k is the integration constant
    
    if nargin < 2
        k = 0;
    end
    
    n = length(p);
    q = zeros(1, n + 1);
    
    for i = 1:n
        q(i) = p(i) / (n - i + 1);
    end
    q(end) = k;
end
