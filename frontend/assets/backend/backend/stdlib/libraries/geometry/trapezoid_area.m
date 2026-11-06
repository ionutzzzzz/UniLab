function A = trapezoid_area(a, b, h)
    if nargin < 1, a = []; end
    if nargin < 2, b = []; end
    if nargin < 3, h = []; end
    A = ((a + b) / 2) * h;
end
