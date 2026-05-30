function [x] = logistic_map(r, x0, n)
    % LOGISTIC_MAP Generate a sequence from the logistic map
    % x_{n+1} = r * x_n * (1 - x_n)
    
    x = zeros(n, 1);
    x(1) = x0;
    for i = 1:n-1
        x(i+1) = r * x(i) * (1 - x(i));
    end
end
