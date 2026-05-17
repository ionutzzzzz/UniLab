function [y, t] = impulse(sys, T)
    if nargin < 2, T = []; end
    [t, y] = unilab_impulse(sys, T);
    if nargout == 0
        plot(t, y);
        title('Impulse Response'); xlabel('Time (s)'); ylabel('Amplitude');
    end
end