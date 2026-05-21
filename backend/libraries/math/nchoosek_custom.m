function [c] = nchoosek_custom(n, k)
    c = factorial_custom(n) / (factorial_custom(k) * factorial_custom(n - k));
end
