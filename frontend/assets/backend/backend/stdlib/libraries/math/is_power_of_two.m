function b = is_power_of_two(n)
    % IS_POWER_OF_TWO Check if n is 2^k
    if nargin < 1, n = []; end
    if n <= 0
        b = false;
    else
        b = (mod(log2(n), 1) == 0);
    end
end
