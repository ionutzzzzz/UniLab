function [y] = sech_custom(x)
    if nargin < 1, x = []; end
    y = 1 ./ cosh_custom(x);
end
