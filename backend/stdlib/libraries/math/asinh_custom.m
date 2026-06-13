function [y] = asinh_custom(x)
    if nargin < 1, x = []; end
    y = log(x + sqrt(x.^2 + 1));
end
