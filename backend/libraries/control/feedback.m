function [sys] = feedback(sys1, sys2)
    % Simplified discrete negative feedback connection for TF
    if nargin < 2, sys2 = tf([1], [1]); end
    num = conv(sys1.num, sys2.den);
    den = sys1.den * sys2.den + sys1.num * sys2.num;
    sys = tf(num, den);
end