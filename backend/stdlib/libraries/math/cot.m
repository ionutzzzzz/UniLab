function y = cot(x)
    % COT Cotangent in radians
    if nargin < 1, x = []; end
    y = cos(x) ./ sin(x);
end
