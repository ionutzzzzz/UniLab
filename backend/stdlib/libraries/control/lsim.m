function [y, t] = lsim(sys, U, T)
    if nargin < 1, sys = []; end
    if nargin < 2, U = []; end
    if nargin < 3, T = []; end
    [t, y] = unilab_lsim(sys, U, T);
    plot(t, y);
    title('Linear Simulation Response'); xlabel('Time (s)'); ylabel('Amplitude');
end