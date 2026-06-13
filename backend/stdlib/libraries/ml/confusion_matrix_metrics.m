function stats = confusion_matrix_metrics(cm)
    % CONFUSION_MATRIX_METRICS Precision, Recall, F1 for each class from CM
    if nargin < 1, cm = []; end
    K = size(cm, 1);
    stats = struct();
    stats.precision = zeros(K, 1);
    stats.recall = zeros(K, 1);
    stats.f1 = zeros(K, 1);
    
    for i = 1:K
        tp = cm(i, i);
        fp = sum(cm(:, i)) - tp;
        fn = sum(cm(i, :)) - tp;
        
        stats.precision(i) = tp / (tp + fp);
        stats.recall(i) = tp / (tp + fn);
        stats.f1(i) = 2 * (stats.precision(i) * stats.recall(i)) / (stats.precision(i) + stats.recall(i));
    end
end
