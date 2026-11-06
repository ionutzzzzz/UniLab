function P = rectangle_perimeter(l, w)
    if nargin < 1, l = []; end
    if nargin < 2, w = []; end
    P = 2 * (l + w);
end
