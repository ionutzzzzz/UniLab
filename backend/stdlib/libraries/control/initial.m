function [y, t, x] = initial(sys, x0, T)
    % INITIAL Initial condition response of state-space system
    % [y, t, x] = initial(sys, x0, T)
    if nargin < 1, sys = []; end
    if nargin < 2, x0 = []; end
    if nargin < 3, T = []; end
    [t_out, y_out, x_out] = unilab_initial(sys, x0, T);
    y = y_out;
    t = t_out;
    x = x_out;
    
    if nargout == 0
        plot(t, y);
        title('Initial Condition Response');
        xlabel('Time (s)'); ylabel('Amplitude');
    end
end
