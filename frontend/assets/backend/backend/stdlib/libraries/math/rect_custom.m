function y = rect_custom(x)
    if nargin < 1, x = []; end
    y = abs(x) <= 0.5;
end
