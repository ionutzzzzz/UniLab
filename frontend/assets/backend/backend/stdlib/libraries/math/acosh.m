function y = acosh(x)
    % ACOSH Inverse hyperbolic cosine
    if nargin < 1, x = []; end
    y = log(x + sqrt(x.^2 - 1));
end
