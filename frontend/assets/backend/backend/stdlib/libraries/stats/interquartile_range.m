function r = interquartile_range(data)
    % INTERQUARTILE_RANGE Difference between 75th and 25th percentiles
    r = quantile(data, 0.75) - quantile(data, 0.25);
end
