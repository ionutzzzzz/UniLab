function a = triangle_area(b, h)
    if nargin < 1, b = []; end
    if nargin < 2, h = []; end
    a = 0.5 * b * h;
end