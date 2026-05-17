function [acc] = accuracy(y_true, y_pred)
    % ACCURACY Calculate the classification accuracy
    % acc = sum(y_true == y_pred) / length(y_true)
    
    y_true = y_true(:);
    y_pred = y_pred(:);
    acc = sum(y_true == y_pred) ./ length(y_true);
end
