function [y] = sech_custom(x)
    y = 1 ./ cosh_custom(x);
end
