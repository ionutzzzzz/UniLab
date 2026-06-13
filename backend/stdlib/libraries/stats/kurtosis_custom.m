function k = kurtosis_custom(data)
    % KURTOSIS_CUSTOM Calculate kurtosis
    if nargin < 1, data = []; end
    m4 = central_moment(data, 4);
    sigma = std(data);
    k = m4 / sigma^4;
end
