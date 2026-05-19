function [y, t] = lsim(sys, U, T)
    [t, y] = unilab_lsim(sys, U, T);
    plot(t, y);
    title('Linear Simulation Response'); xlabel('Time (s)'); ylabel('Amplitude');
end