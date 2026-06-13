function [p] = is_even(n)
    % IS_EVEN Returns 1 if n is even, 0 otherwise
    if nargin < 1, n = []; end
    p = (mod(n, 2) == 0);
end
