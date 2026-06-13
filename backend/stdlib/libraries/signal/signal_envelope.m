function env = signal_envelope(x)
    % SIGNAL_ENVELOPE Simple envelope detection using moving RMS
    if nargin < 1, x = []; end
    env = moving_average(abs(x), 10);
end
