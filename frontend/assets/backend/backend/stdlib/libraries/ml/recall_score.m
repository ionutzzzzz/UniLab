function [rec] = recall_score(y_true, y_pred)
    % RECALL_SCORE Calculate recall for binary classification (class 1)
    if nargin < 1, y_true = []; end
    if nargin < 2, y_pred = []; end
    y_true = y_true(:);
    y_pred = y_pred(:);
    tp = sum((y_true == 1) & (y_pred == 1));
    fn = sum((y_true == 1) & (y_pred == 0));
    if (tp + fn) == 0, rec = 0; else, rec = tp / (tp + fn); end
end
