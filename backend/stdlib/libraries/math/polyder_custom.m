function [q] = polyder_custom(p)
    % POLYDER_CUSTOM Differentiate polynomial p
    
    n = length(p);
    if n <= 1
        q = 0;
        return;
    end
    
    q = zeros(1, n - 1);
    for i = 1:n-1
        q(i) = p(i) * (n - i);
    end
end
