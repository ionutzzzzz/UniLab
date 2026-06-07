function [y] = asinh_custom(x)
    y = log(x + sqrt(x.^2 + 1));
end
