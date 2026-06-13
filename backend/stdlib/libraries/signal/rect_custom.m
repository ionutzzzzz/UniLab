function y = rect_custom(x)
    if nargin < 1, x = []; end
    y = zeros(size(x));
    y(abs(x) < 0.5) = 1;
    y(abs(x) == 0.5) = 0.5;
end
