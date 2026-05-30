function g = geometric_mean(data)
    % GEOMETRIC_MEAN Geometric mean of data
    g = exp(mean(log(data)));
end
