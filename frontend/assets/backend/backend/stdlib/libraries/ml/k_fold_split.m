function [folds] = k_fold_split(n_samples, k)
    % K_FOLD_SPLIT Generate indices for k-fold cross validation
    % [folds] = k_fold_split(n_samples, k)
    
    indices = randperm(n_samples);
    fold_size = floor(n_samples / k);
    
    folds = cell(k, 1);
    
    for i = 1:k
        start_idx = (i-1) * fold_size + 1;
        if i == k
            end_idx = n_samples;
        else
            end_idx = i * fold_size;
        end
        
        test_idx = indices(start_idx:end_idx);
        train_idx = [indices(1:start_idx-1), indices(end_idx+1:end)];
        
        folds(i) = struct('train', train_idx, 'test', test_idx);
    end
end
