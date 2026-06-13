function y = sinc_custom(x)
    if nargin < 1, x = []; end
    y = ones(size(x));
    idx = x ~= 0;
    y(idx) = sin(pi() * x(idx)) ./ (pi() * x(idx));
end
