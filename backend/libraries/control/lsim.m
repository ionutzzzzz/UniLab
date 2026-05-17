function [y, t] = lsim(sys, U, T)
    [t, y] = unilab_lsim(sys, U, T);
    if nargout == 0
        plot(t, y);
        title('Linear Simulation Response'); xlabel('Time (s)'); ylabel('Amplitude');
    end
end