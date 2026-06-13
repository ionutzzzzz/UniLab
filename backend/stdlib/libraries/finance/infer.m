function [res, v] = infer(model, data)
    % INFER Infers residuals
    
    if nargin < 1, model = []; end
    if nargin < 2, data = []; end
    fprintf('Inferring residuals for %s model...\n', model.Type);
    res = data - mean(data);
    v = var(data) * ones(size(data));
end
