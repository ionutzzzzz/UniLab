function g = geometric_mean(data)
    % GEOMETRIC_MEAN Geometric mean of data
    if nargin < 1, data = []; end
    g = exp(mean(log(data)));
end
