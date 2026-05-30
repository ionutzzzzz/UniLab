function [sys] = feedback(sys1, sys2, sign)
    if nargin < 2, sys2 = tf([1], [1]); end
    if nargin < 3, sign = -1; end
    sys = unilab_feedback(sys1, sys2, sign);
end