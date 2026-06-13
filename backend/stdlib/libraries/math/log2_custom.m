function [y] = log2_custom(x)
    if nargin < 1, x = []; end
    y = log(x) / log(2);
end
