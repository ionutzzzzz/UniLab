function [err] = mae(y_true, y_pred)
    % MAE Calculate Mean Absolute Error
    if nargin < 1, y_true = []; end
    if nargin < 2, y_pred = []; end
    err = mean(abs(y_true(:) - y_pred(:)));
end
