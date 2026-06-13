function [R] = correlation_matrix(data)
    % Calculates the Pearson correlation matrix
    % data: Matrix where columns are variables and rows are observations

    % Ensure data is properly formatted and 2D
    if nargin < 1, data = []; end
    if isvector(data)
        data = reshape(data, [], 1);
    end

    [n, m] = size(data);

    if m < 1
        R = [];
        return;
    end

    R = eye(m);

    for i = 1:m
        for j = i+1:m
            x = data(:, i);
            y = data(:, j);

            x_mean = mean(x);
            y_mean = mean(y);

            x_m = (x - x_mean);
            y_m = (y - y_mean);

            numerator = sum(x_m .* y_m);
            denominator = (sqrt(sum(x_m .^ 2)) * sqrt(sum(y_m .^ 2)));

            if denominator > 0
                c = numerator / denominator;
            else
                c = 0;
            end

            R(i, j) = c;
            R(j, i) = c;
        end
    end
end
