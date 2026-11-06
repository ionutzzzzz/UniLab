function A = rectangle_area(l, w)
    if nargin < 1, l = []; end
    if nargin < 2, w = []; end
    A = l * w;
end
