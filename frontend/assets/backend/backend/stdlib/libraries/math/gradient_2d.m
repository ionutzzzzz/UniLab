function [fx, fy] = gradient_2d(F, dx, dy)
    % GRADIENT_2D Numerical gradient of a 2D field
    % [fx, fy] = gradient_2d(F, dx, dy)
    
    if nargin < 1, F = []; end
    if nargin < 2, dx = []; end
    if nargin < 3, dy = []; end
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
