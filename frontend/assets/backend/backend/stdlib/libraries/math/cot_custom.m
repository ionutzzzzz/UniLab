function [y] = cot_custom(x)
    if nargin < 1, x = []; end
    y = cos(x) ./ sin(x);
end
