function obj = fillts(obj, method)
    % FILLTS Handles NaNs in the data
    
    if nargin < 1, obj = []; end
    if nargin < 2
        method = 'linear';
    end
    
    data = obj.data;
    nan_mask = isnan(data);
    if any(nan_mask(:))
        % Simple zero fill for mock
        data(nan_mask) = 0;
        fprintf('Filled NaNs using method: %s (Mock: zero fill)\n', method);
    end
    obj.data = data;
end
