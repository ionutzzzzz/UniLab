function A = rhombus_area(d1, d2)
    if nargin < 1, d1 = []; end
    if nargin < 2, d2 = []; end
    A = (d1 * d2) / 2;
end
