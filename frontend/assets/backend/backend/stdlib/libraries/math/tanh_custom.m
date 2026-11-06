function [y] = tanh_custom(x)
    if nargin < 1, x = []; end
    y = sinh_custom(x) ./ cosh_custom(x);
end
