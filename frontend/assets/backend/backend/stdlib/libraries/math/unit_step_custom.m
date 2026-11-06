function y = unit_step_custom(x)
    if nargin < 1, x = []; end
    y = x >= 0;
end
