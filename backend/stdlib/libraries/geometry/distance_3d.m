function d = distance_3d(x1, y1, z1, x2, y2, z2)
    if nargin < 1, x1 = []; end
    if nargin < 2, y1 = []; end
    if nargin < 3, z1 = []; end
    if nargin < 4, x2 = []; end
    if nargin < 5, y2 = []; end
    if nargin < 6, z2 = []; end
    d = sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2);
end