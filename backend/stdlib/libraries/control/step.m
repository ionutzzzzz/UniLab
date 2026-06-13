function [y, t] = step(sys, T)
    if nargin < 1, sys = []; end
    if nargin < 2, T = []; end
    [t, y] = unilab_step(sys, T);
    plot(t, y);
    title('Step Response'); xlabel('Time (s)'); ylabel('Amplitude');
end