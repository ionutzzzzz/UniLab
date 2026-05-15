function [I] = trapz_custom(y, x)
    % TRAPZ_CUSTOM Numerical integration using the trapezoidal rule
    % [I] = trapz_custom(y, x)
    
    n = length(y);
    I = 0;
    
    if length(x) == 1
        h = x;
        for i = 1:n-1
            I = I + (y(i) + y(i+1)) * h / 2;
        end
    else
        for i = 1:n-1
            h = x(i+1) - x(i);
            I = I + (y(i) + y(i+1)) * h / 2;
        end
    end
end
