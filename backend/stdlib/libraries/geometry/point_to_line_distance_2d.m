function d = point_to_line_distance_2d(px, py, x1, y1, x2, y2)
    % POINT_TO_LINE_DISTANCE_2D Shortest distance from a point to a line
    if nargin < 1, px = []; end
    if nargin < 2, py = []; end
    if nargin < 3, x1 = []; end
    if nargin < 4, y1 = []; end
    if nargin < 5, x2 = []; end
    if nargin < 6, y2 = []; end
    num = abs((x2 - x1) * (y1 - py) - (x1 - px) * (y2 - y1));
    den = sqrt((x2 - x1)^2 + (y2 - y1)^2);
    d = num / den;
end
