function [err] = mae(y_true, y_pred)
    % MAE Calculate Mean Absolute Error
    err = mean(abs(y_true(:) - y_pred(:)));
end
