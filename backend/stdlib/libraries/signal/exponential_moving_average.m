function y = exponential_moving_average(x, alpha)
    % EXPONENTIAL_MOVING_AVERAGE EMA filter
    % y[n] = alpha * x[n] + (1 - alpha) * y[n-1]
    y = zeros(size(x));
    y(1) = x(1);
    for i = 2:length(x)
        y(i) = alpha * x(i) + (1 - alpha) * y(i-1);
    end
end
