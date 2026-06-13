function m = midpoint_3d(x1, y1, z1, x2, y2, z2)
    if nargin < 1, x1 = []; end
    if nargin < 2, y1 = []; end
    if nargin < 3, z1 = []; end
    if nargin < 4, x2 = []; end
    if nargin < 5, y2 = []; end
    if nargin < 6, z2 = []; end
    m = [(x1 + x2)/2, (y1 + y2)/2, (z1 + z2)/2];
end