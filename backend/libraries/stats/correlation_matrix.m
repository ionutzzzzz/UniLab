function [R] = correlation_matrix(data)
    % Calculates the Pearson correlation matrix
    % data: Matrix where columns are variables and rows are observations
    
    [n, m] = size(data);
    R = eye(m);
    
    for i = 1:m
        for j = i+1:m
            x = data(:, i);
            y = data(:, j);
            
            x_m = (x - mean(x));
            y_m = (y - mean(y));
            
            c = (sum(x_m .* y_m) / (sqrt(sum(x_m .^ 2)) * sqrt(sum(y_m .^ 2))));
            R(i, j) = c;
            R(j, i) = c;
        end
    end
end
