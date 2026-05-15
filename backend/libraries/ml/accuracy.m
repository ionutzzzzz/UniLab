function [acc] = accuracy(y_true, y_pred)
    % ACCURACY Calculate the classification accuracy
    % acc = sum(y_true == y_pred) / length(y_true)
    
    acc = sum(y_true == y_pred) ./ length(y_true);
end
