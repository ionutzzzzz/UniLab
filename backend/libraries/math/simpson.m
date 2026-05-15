function [I] = simpson(y, x)
    % SIMPSON Numerical integration using Simpson's 1/3 rule
    % Requires evenly spaced points and an odd number of points
    % [I] = simpson(y, x)
    
    n = length(y);
    if mod(n, 2) == 0
        % If even number of points, use trapezoidal for the last interval
        I = simpson(y(1:n-1), x(1:n-1)) + trapz_custom(y(n-1:n), x(n-1:n));
        return;
    end
    
    if length(x) == 1
        h = x;
    else
        h = x(2) - x(1);
    end
    
    I = y(1) + y(n);
    for i = 2:2:n-1
        I = I + 4 * y(i);
    end
    for i = 3:2:n-2
        I = I + 2 * y(i);
    end
    
    I = I * h / 3;
end
