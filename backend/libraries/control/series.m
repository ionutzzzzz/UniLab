function [sys] = series(sys1, sys2)
    % Simplified discrete series connection for TF
    sys = tf(conv(sys1.num, sys2.num), conv(sys1.den, sys2.den));
end