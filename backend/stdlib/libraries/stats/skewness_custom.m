function s = skewness_custom(data)
    % SKEWNESS_CUSTOM Calculate skewness
    m3 = central_moment(data, 3);
    sigma = std(data);
    s = m3 / sigma^3;
end
