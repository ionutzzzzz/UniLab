function loss = binary_cross_entropy(y_true, y_pred)
    eps = 1e-15;
    y_pred = max(eps, min(1 - eps, y_pred));
    loss = -mean(y_true .* log(y_pred) + (1 - y_true) .* log(1 - y_pred));
end
