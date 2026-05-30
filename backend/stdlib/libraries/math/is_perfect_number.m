function b = is_perfect_number(n)
    % IS_PERFECT_NUMBER Check if n is a perfect number
    % A perfect number is a positive integer that is equal to the sum of its positive divisors, excluding itself.
    if n <= 1
        b = false;
        return;
    end
    sum_div = 1;
    for i = 2:sqrt(n)
        if mod(n, i) == 0
            sum_div = sum_div + i;
            if i*i ~= n
                sum_div = sum_div + n/i;
            end
        end
    end
    b = (sum_div == n);
end
