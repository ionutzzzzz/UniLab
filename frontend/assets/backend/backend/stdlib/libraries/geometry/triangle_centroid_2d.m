function [cx, cy] = triangle_centroid_2d(x1, y1, x2, y2, x3, y3)
    % TRIANGLE_CENTROID_2D Centroid of a triangle
    if nargin < 1, x1 = []; end
    if nargin < 2, y1 = []; end
    if nargin < 3, x2 = []; end
    if nargin < 4, y2 = []; end
    if nargin < 5, x3 = []; end
    if nargin < 6, y3 = []; end
    cx = (x1 + x2 + x3) / 3;
    cy = (y1 + y2 + y3) / 3;
end
