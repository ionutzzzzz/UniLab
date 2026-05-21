function [X_lda] = lda_predict(X, W)
    % LDA_PREDICT Project data onto LDA components
    % [X_lda] = lda_predict(X, W)
    
    X_lda = X * W;
end
