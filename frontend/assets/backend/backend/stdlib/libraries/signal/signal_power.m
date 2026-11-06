function p = signal_power(x)
    % SIGNAL_POWER Average energy per sample
    if nargin < 1, x = []; end
    p = mean(x.^2);
end
