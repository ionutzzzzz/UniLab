function [cm] = confusion_matrix(y_true, y_pred, num_classes)
    % CONFUSION_MATRIX Calculate the confusion matrix
    % [cm] = confusion_matrix(y_true, y_pred, num_classes)
    
    if nargin < 1, y_true = []; end
    if nargin < 2, y_pred = []; end
    if nargin < 3, num_classes = []; end
    cm = zeros(num_classes, num_classes);
    for i = 1:length(y_true)
        cm(y_true(i), y_pred(i)) = cm(y_true(i), y_pred(i)) + 1;
    end
end
