function cov = covariance_custom(x, y)
    n = length(x);
    mx = mean(x);
    my = mean(y);
    cov = sum((x - mx) .* (y - my)) / (n - 1);
end
