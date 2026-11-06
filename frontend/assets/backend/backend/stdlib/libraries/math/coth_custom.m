function [y] = coth_custom(x)
    if nargin < 1, x = []; end
    y = cosh_custom(x) ./ sinh_custom(x);
end
