function [err] = mse(y_true, y_pred)
    % MSE Calculate the Mean Squared Error
    % err = mean((y_true - y_pred).^2)
    err = mean((y_true - y_pred).^2);
end
