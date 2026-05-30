function [y] = tanh_custom(x)
    y = sinh_custom(x) ./ cosh_custom(x);
end
