function [y, t] = step(sys, T)
    if nargin < 2, T = []; end
    [t, y] = unilab_step(sys, T);
    if nargout == 0
        plot(t, y);
        title('Step Response'); xlabel('Time (s)'); ylabel('Amplitude');
    end
end