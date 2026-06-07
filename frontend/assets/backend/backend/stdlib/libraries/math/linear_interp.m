function [y_interp] = linear_interp(x, y, x_interp)
    % LINEAR_INTERP Linear interpolation
    % [y_interp] = linear_interp(x, y, x_interp)
    
    m = length(x_interp);
    y_interp = zeros(size(x_interp));
    
    for i = 1:m
        xi = x_interp(i);
        % Find the interval [x_j, x_{j+1}] containing xi
        idx = find(x <= xi);
        if isempty(idx)
            y_interp(i) = y(1);
            continue;
        end
        j = idx(end);
        
        if j == length(x)
            y_interp(i) = y(end);
        else
            % Linear formula: y = y0 + (y1 - y0) * (x - x0) / (x1 - x0)
            y_interp(i) = y(j) + (y(j+1) - y(j)) * (xi - x(j)) / (x(j+1) - x(j));
        end
    end
end
