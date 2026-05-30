function loss = huber_loss(y_true, y_pred, delta)
    err = abs(y_true - y_pred);
    quadratic = min(err, delta);
    linear = err - quadratic;
    loss = mean(0.5 * quadratic.^2 + delta * linear);
end
