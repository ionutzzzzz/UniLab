function [y] = sinh_custom(x)
    if nargin < 1, x = []; end
    y = (exp(x) - exp(-x)) / 2;
end
