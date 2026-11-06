function y = asinh(x)
    % ASINH Inverse hyperbolic sine
    if nargin < 1, x = []; end
    y = log(x + sqrt(x.^2 + 1));
end
