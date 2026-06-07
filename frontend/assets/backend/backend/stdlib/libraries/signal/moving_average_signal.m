function y = moving_average_signal(x, L)
    % MOVING_AVERAGE_SIGNAL Simple moving average filter
    b = ones(1, L) / L;
    a = 1;
    y = filter(b, a, x);
end
