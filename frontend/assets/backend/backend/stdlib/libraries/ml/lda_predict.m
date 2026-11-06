function [X_lda] = lda_predict(X, W)
    % LDA_PREDICT Project data onto LDA components
    % [X_lda] = lda_predict(X, W)
    
    if nargin < 1, X = []; end
    if nargin < 2, W = []; end
    X_lda = X * W;
end
