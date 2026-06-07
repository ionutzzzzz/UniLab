function d = point_to_line_distance_2d(px, py, x1, y1, x2, y2)
    % POINT_TO_LINE_DISTANCE_2D Shortest distance from a point to a line
    num = abs((x2 - x1) * (y1 - py) - (x1 - px) * (y2 - y1));
    den = sqrt((x2 - x1)^2 + (y2 - y1)^2);
    d = num / den;
end
