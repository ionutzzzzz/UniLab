function m = central_moment(data, n)
    % CENTRAL_MOMENT Calculate the n-th central moment
    if nargin < 1, data = []; end
    if nargin < 2, n = []; end
    mu = mean(data);
    m = mean((data - mu).^n);
end
