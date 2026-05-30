function [stump] = decision_stump_train(X, y, weights)
    % DECISION_STUMP_TRAIN Train a one-level decision tree with weighted samples
    
    [m, n] = size(X);
    best_err = 1e9;
    stump = struct();
    
    for feat_idx = 1:n
        thresholds = unique(X(:, feat_idx));
        for i = 1:length(thresholds)
            threshold = thresholds(i);
            
            % Try both polarities
            for p = [1, -1]
                preds = ones(m, 1);
                if p == 1
                    preds(X(:, feat_idx) <= threshold) = -1;
                else
                    preds(X(:, feat_idx) > threshold) = -1;
                end
                
                % Error is the sum of weights of misclassified samples
                err = sum(weights(preds ~= y));
                
                if err < best_err
                    best_err = err;
                    stump.feature_idx = feat_idx;
                    stump.threshold = threshold;
                    stump.polarity = p;
                    stump.error = err;
                end
            end
        end
    end
end
