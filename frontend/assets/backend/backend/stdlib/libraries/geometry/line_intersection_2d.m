function [xi, yi] = line_intersection_2d(x1, y1, x2, y2, x3, y3, x4, y4)
    % LINE_INTERSECTION_2D Find intersection point of two lines
    if nargin < 1, x1 = []; end
    if nargin < 2, y1 = []; end
    if nargin < 3, x2 = []; end
    if nargin < 4, y2 = []; end
    if nargin < 5, x3 = []; end
    if nargin < 6, y3 = []; end
    if nargin < 7, x4 = []; end
    if nargin < 8, y4 = []; end
    den = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if abs(den) < 1e-12
        xi = nan; yi = nan;
        return;
    end
    xi = ((x1*y2 - y1*x2)*(x3 - x4) - (x1 - x2)*(x3*y4 - y3*x4)) / den;
    yi = ((x1*y2 - y1*x2)*(y3 - y4) - (y1 - y2)*(x3*y4 - y3*x4)) / den;
end
