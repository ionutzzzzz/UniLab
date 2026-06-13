function m = midpoint_2d(x1, y1, x2, y2)
    if nargin < 1, x1 = []; end
    if nargin < 2, y1 = []; end
    if nargin < 3, x2 = []; end
    if nargin < 4, y2 = []; end
    m = [(x1 + x2)/2, (y1 + y2)/2];
end