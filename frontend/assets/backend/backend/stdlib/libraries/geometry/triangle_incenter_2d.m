function [ix, iy] = triangle_incenter_2d(x1, y1, x2, y2, x3, y3)
    % TRIANGLE_INCENTER_2D Incenter of a triangle
    if nargin < 1, x1 = []; end
    if nargin < 2, y1 = []; end
    if nargin < 3, x2 = []; end
    if nargin < 4, y2 = []; end
    if nargin < 5, x3 = []; end
    if nargin < 6, y3 = []; end
    a = sqrt((x2 - x3)^2 + (y2 - y3)^2);
    b = sqrt((x1 - x3)^2 + (y1 - y3)^2);
    c = sqrt((x1 - x2)^2 + (y1 - y2)^2);
    p = a + b + c;
    ix = (a*x1 + b*x2 + c*x3) / p;
    iy = (a*y1 + b*y2 + c*y3) / p;
end
