function A = ellipse_area(a, b)
    if nargin < 1, a = []; end
    if nargin < 2, b = []; end
    A = pi() * a * b;
end
