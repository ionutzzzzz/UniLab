function [area] = poly_area(x, y)
    % POLY_AREA Calculate area of a polygon using the Shoelace formula
    % [area] = poly_area(x, y)
    
    if nargin < 1, x = []; end
    if nargin < 2, y = []; end
    n = length(x);
    area = 0;
    for i = 1:n
        j = mod(i, n) + 1;
        area = area + x(i) * y(j);
        area = area - x(j) * y(i);
    end
    area = abs(area) / 2;
end
