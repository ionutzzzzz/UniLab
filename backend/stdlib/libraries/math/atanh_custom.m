function [y] = atanh_custom(x)
    y = 0.5 * log((1 + x) ./ (1 - x));
end
