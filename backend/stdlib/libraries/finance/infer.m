function [res, v] = infer(model, data)
    % INFER Infers residuals
    
    fprintf('Inferring residuals for %s model...\n', model.Type);
    res = data - mean(data);
    v = var(data) * ones(size(data));
end
