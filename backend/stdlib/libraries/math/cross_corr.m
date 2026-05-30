function [c] = cross_corr(x, y)
    % CROSS_CORR Circular cross-correlation of two signals
    
    n = length(x);
    c = zeros(n, 1);
    for k = 1:n
        sum_val = 0;
        for i = 1:n
            j = mod(i + k - 2, n) + 1;
            sum_val = sum_val + x(i) * y(j);
        end
        c(k) = sum_val;
    end
end
