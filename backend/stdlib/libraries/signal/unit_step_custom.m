function y = unit_step_custom(x)
    if nargin < 1, x = []; end
    y = zeros(size(x));
    y(x >= 0) = 1;
end
