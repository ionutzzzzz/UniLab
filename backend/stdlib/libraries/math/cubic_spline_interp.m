function yi = cubic_spline_interp(x, y, xi)
    % CUBIC_SPLINE_INTERP Cubic spline interpolation
    if nargin < 1, x = []; end
    if nargin < 2, y = []; end
    if nargin < 3, xi = []; end
    yi = spline(x, y, xi);
end
