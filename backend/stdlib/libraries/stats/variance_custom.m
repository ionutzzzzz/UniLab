function v = variance_custom(data)
    n = length(data);
    m = mean(data);
    v = sum((data - m).^2) / (n - 1);
end
