function [cx, cy] = triangle_centroid_2d(x1, y1, x2, y2, x3, y3)
    % TRIANGLE_CENTROID_2D Centroid of a triangle
    cx = (x1 + x2 + x3) / 3;
    cy = (y1 + y2 + y3) / 3;
end
