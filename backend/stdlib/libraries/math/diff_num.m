function [dy] = diff_num(y, x)
    % DIFF_NUM Numerical derivative of y with respect to x
    % Uses central differences for interior points and forward/backward for edges
    % [dy] = diff_num(y, x)
    
    n = length(y);
    dy = zeros(size(y));
    
    if n < 2
        return;
    end
    
    % Check if x is scalar (spacing) or vector
    if length(x) == 1
        h = x;
        % Forward difference for first point
        dy(1) = (y(2) - y(1)) / h;
        % Central difference for interior
        for i = 2:n-1
            dy(i) = (y(i+1) - y(i-1)) / (2 * h);
        end
        % Backward difference for last point
        dy(n) = (y(n) - y(n-1)) / h;
    else
        % Forward difference for first point
        dy(1) = (y(2) - y(1)) / (x(2) - x(1));
        % Central difference for interior
        for i = 2:n-1
            dy(i) = (y(i+1) - y(i-1)) / (x(i+1) - x(i-1));
        end
        % Backward difference for last point
        dy(n) = (y(n) - y(n-1)) / (x(n) - x(n-1));
    end
end
