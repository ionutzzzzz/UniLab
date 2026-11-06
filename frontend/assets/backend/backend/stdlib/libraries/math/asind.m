function y = asind(x)
    % ASIND Inverse sine in degrees
    if nargin < 1, x = []; end
    y = rad2deg_custom(asin(x));
end
