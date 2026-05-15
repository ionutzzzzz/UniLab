function [f1] = f1_score(y_true, y_pred)
    % F1_SCORE Calculate the F1 score for binary classification
    % [f1] = f1_score(y_true, y_pred)
    
    tp = sum((y_true == 1) & (y_pred == 1));
    fp = sum((y_true == 0) & (y_pred == 1));
    fn = sum((y_true == 1) & (y_pred == 0));
    
    precision = tp ./ (tp + fp);
    recall = tp ./ (tp + fn);
    
    f1 = 2 * (precision .* recall) ./ (precision + recall);
end
