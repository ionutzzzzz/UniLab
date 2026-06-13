function loss = huber_loss(y_true, y_pred, delta)
    if nargin < 1, y_true = []; end
    if nargin < 2, y_pred = []; end
    if nargin < 3, delta = []; end
    err = abs(y_true - y_pred);
    quadratic = min(err, delta);
    linear = err - quadratic;
    loss = mean(0.5 * quadratic.^2 + delta * linear);
end
