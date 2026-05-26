function [p] = is_even(n)
    % IS_EVEN Returns 1 if n is even, 0 otherwise
    p = (mod(n, 2) == 0);
end
