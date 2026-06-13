function val = hermite_interp(x0, y0, dy0, x1, y1, dy1, xi)
    % HERMITE_INTERP Cubic Hermite interpolation between two points
    if nargin < 1, x0 = []; end
    if nargin < 2, y0 = []; end
    if nargin < 3, dy0 = []; end
    if nargin < 4, x1 = []; end
    if nargin < 5, y1 = []; end
    if nargin < 6, dy1 = []; end
    if nargin < 7, xi = []; end
    h = x1 - x0;
    t = (xi - x0) / h;
    
    h00 = 2*t^3 - 3*t^2 + 1;
    h10 = t^3 - 2*t^2 + t;
    h01 = -2*t^3 + 3*t^2;
    h11 = t^3 - t^2;
    
    val = h00*y0 + h10*h*dy0 + h01*y1 + h11*h*dy1;
end
