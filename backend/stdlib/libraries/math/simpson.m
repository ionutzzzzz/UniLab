function I = simpson(y, x)
    % SIMPSON Simpson's rule
    n = length(x) - 1;
    if mod(n, 2) ~= 0
        error('Number of intervals must be even');
    end
    h = (x(end) - x(1)) / n;
    I = y(1) + y(end) + 4 * sum(y(2:2:end-1)) + 2 * sum(y(3:2:end-2));
    I = I * h / 3;
end
