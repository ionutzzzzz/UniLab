function v = variance_custom(data)
    if nargin < 1, data = []; end
    n = length(data);
    m = mean(data);
    v = sum((data - m).^2) / (n - 1);
end
