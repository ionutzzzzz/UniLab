function [err] = mse(y_true, y_pred)
    % MSE Calculate the Mean Squared Error
    % err = mean((y_true - y_pred).^2)
    if nargin < 1, y_true = []; end
    if nargin < 2, y_pred = []; end
    err = mean((y_true - y_pred).^2);
end
