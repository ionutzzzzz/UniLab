function p = triangle_perimeter(a, b, c)
    if nargin < 1, a = []; end
    if nargin < 2, b = []; end
    if nargin < 3, c = []; end
    p = a + b + c;
end