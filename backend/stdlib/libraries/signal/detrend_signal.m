function y = detrend_signal(x)
    % DETREND_SIGNAL Remove linear trend
    if nargin < 1, x = []; end
    n = length(x);
    t = (1:n)';
    p = poly_fit_linear(t, x);
    trend = p(1)*t + p(2);
    y = x - trend;
end
