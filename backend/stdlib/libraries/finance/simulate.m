function [paths, v] = simulate(model, num_periods)
    % SIMULATE Generates paths
    
    if nargin < 1, model = []; end
    if nargin < 2, num_periods = []; end
    fprintf('Simulating %d periods using %s model...\n', num_periods, model.Type);
    if strcmp(model.Type, 'VAR')
        paths = randn(num_periods, model.NumSeries);
        v = repmat(eye(model.NumSeries), [1, 1, num_periods]);
    else
        paths = randn(num_periods, 1);
        v = ones(num_periods, 1);
    end
end
