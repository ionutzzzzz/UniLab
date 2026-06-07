function loss = hinge_loss(y_true, y_pred)
    % y_true should be -1 or 1
    loss = mean(max(0, 1 - y_true .* y_pred));
end
