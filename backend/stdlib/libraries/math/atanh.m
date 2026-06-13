function y = atanh(x)
    % ATANH Inverse hyperbolic tangent
    if nargin < 1, x = []; end
    y = 0.5 * log((1 + x) ./ (1 - x));
end
