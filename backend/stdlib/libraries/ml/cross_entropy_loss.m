function [loss] = cross_entropy_loss(y_true, y_pred)
    % CROSS_ENTROPY_LOSS Calculate the cross entropy loss
    % loss = -sum(y_true * log(y_pred))
    
    % Avoid log(0)
    if nargin < 1, y_true = []; end
    if nargin < 2, y_pred = []; end
    eps = 1e-15;
    y_pred = max(min(y_pred, 1 - eps), eps);
    
    m = size(y_true, 1);
    loss = -sum(sum(y_true .* log(y_pred))) ./ m;
end
