function [p] = is_odd(n)
    % IS_ODD Returns 1 if n is odd, 0 otherwise
    p = (mod(n, 2) ~= 0);
end
