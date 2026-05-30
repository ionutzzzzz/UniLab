function [xi, yi] = line_intersection_2d(x1, y1, x2, y2, x3, y3, x4, y4)
    % LINE_INTERSECTION_2D Find intersection point of two lines
    den = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if abs(den) < 1e-12
        xi = nan; yi = nan;
        return;
    end
    xi = ((x1*y2 - y1*x2)*(x3 - x4) - (x1 - x2)*(x3*y4 - y3*x4)) / den;
    yi = ((x1*y2 - y1*x2)*(y3 - y4) - (y1 - y2)*(x3*y4 - y3*x4)) / den;
end
