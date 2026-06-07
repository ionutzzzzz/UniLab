function [sys] = parallel(sys1, sys2)
    % Simplified discrete parallel connection for TF
    num = sys1.num * sys2.den + sys2.num * sys1.den;
    den = conv(sys1.den, sys2.den);
    sys = tf(num, den);
end