function [y_interp] = lagrange_interp(x, y, x_interp)
    % LAGRANGE_INTERP Lagrange polynomial interpolation
    % [y_interp] = lagrange_interp(x, y, x_interp)
    
    if nargin < 1, x = []; end
    if nargin < 2, y = []; end
    if nargin < 3, x_interp = []; end
    n = length(x);
    m = length(x_interp);
    y_interp = zeros(size(x_interp));
    
    for k = 1:m
        val = 0;
        for i = 1:n
            L = 1;
            for j = 1:n
                if i ~= j
                    L = L .* (x_interp(k) - x(j)) ./ (x(i) - x(j));
                end
            end
            val = val + y(i) * L;
        end
        y_interp(k) = val;
    end
end
