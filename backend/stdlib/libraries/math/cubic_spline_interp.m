function yi = cubic_spline_interp(x, y, xi)
    % CUBIC_SPLINE_INTERP Cubic spline interpolation
    yi = spline(x, y, xi);
end
