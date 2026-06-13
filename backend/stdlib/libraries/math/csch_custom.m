function [y] = csch_custom(x)
    if nargin < 1, x = []; end
    y = 1 ./ sinh_custom(x);
end
