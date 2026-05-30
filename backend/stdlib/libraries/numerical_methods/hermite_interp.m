function val = hermite_interp(x0, y0, dy0, x1, y1, dy1, xi)
    % HERMITE_INTERP Cubic Hermite interpolation between two points
    h = x1 - x0;
    t = (xi - x0) / h;
    
    h00 = 2*t^3 - 3*t^2 + 1;
    h10 = t^3 - 2*t^2 + t;
    h01 = -2*t^3 + 3*t^2;
    h11 = t^3 - t^2;
    
    val = h00*y0 + h10*h*dy0 + h01*y1 + h11*h*dy1;
end
