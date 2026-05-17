function [prec] = precision_score(y_true, y_pred)
    % PRECISION_SCORE Calculate precision for binary classification (class 1)
    y_true = y_true(:);
    y_pred = y_pred(:);
    tp = sum((y_true == 1) & (y_pred == 1));
    fp = sum((y_true == 0) & (y_pred == 1));
    if (tp + fp) == 0, prec = 0; else, prec = tp / (tp + fp); end
end
