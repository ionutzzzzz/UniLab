function [fx, fy] = gradient_2d(F, dx, dy)
    % GRADIENT_2D Numerical gradient of a 2D field
    % [fx, fy] = gradient_2d(F, dx, dy)
    
    [rows, cols] = size(F);
    fx = zeros(rows, cols);
    fy = zeros(rows, cols);
    
    % Gradient in X (columns)
    for i = 1:rows
        fx(i, :) = diff_num(F(i, :), dx);
    end
    
    % Gradient in Y (rows)
    for j = 1:cols
        fy(:, j) = diff_num(F(:, j), dy);
    end
end
