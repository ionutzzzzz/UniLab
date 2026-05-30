function [y] = coth_custom(x)
    y = cosh_custom(x) ./ sinh_custom(x);
end
