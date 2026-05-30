function y = nchoosek_custom(n, k)
    y = factorial(n) / (factorial(k) * factorial(n-k));
end
