function [y] = csc_custom(x)
    if nargin < 1, x = []; end
    y = 1 ./ sin(x);
end
