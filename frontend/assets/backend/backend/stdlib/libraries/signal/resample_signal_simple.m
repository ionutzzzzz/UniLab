function y = resample_signal_simple(x, L)
    % RESAMPLE_SIGNAL_SIMPLE Resample signal to length L using linear interpolation
    if nargin < 1, x = []; end
    if nargin < 2, L = []; end
    n = length(x);
    t_old = linspace(0, 1, n);
    t_new = linspace(0, 1, L);
    y = linear_interp(t_old, x, t_new);
end
