function [ix, iy] = triangle_incenter_2d(x1, y1, x2, y2, x3, y3)
    % TRIANGLE_INCENTER_2D Incenter of a triangle
    a = sqrt((x2 - x3)^2 + (y2 - y3)^2);
    b = sqrt((x1 - x3)^2 + (y1 - y3)^2);
    c = sqrt((x1 - x2)^2 + (y1 - y2)^2);
    p = a + b + c;
    ix = (a*x1 + b*x2 + c*x3) / p;
    iy = (a*y1 + b*y2 + c*y3) / p;
end
