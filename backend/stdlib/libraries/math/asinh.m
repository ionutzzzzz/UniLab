function y = asinh(x)
    % ASINH Inverse hyperbolic sine
    y = log(x + sqrt(x.^2 + 1));
end
