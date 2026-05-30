function [p] = npermutek_custom(n, k)
    p = factorial_custom(n) / factorial_custom(n - k);
end
