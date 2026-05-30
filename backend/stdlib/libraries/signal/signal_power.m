function p = signal_power(x)
    % SIGNAL_POWER Average energy per sample
    p = mean(x.^2);
end
