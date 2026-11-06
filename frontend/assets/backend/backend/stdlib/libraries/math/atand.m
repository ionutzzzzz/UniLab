function y = atand(x)
    % ATAND Inverse tangent in degrees
    if nargin < 1, x = []; end
    y = rad2deg_custom(atan(x));
end
