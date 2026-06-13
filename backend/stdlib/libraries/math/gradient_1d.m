function [g] = gradient_1d(y, dx)
    % GRADIENT_1D Numerical gradient of a 1D array
    if nargin < 1, y = []; end
    if nargin < 2
        dx = 1;
    end
    g = diff_num(y, dx);
end
