function y = unit_step_custom(x)
    y = zeros(size(x));
    y(x >= 0) = 1;
end
