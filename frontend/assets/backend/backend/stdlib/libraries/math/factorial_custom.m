function [f] = factorial_custom(n)
    if nargin < 1, n = []; end
    f = prod(1:n);
end
