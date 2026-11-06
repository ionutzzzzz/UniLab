function [y] = sec_custom(x)
    if nargin < 1, x = []; end
    y = 1 ./ cos(x);
end
