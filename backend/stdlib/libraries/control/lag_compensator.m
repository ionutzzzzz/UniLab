function sys = lag_compensator(Kc, z, p)
    % LAG_COMPENSATOR Create a lag compensator C(s) = Kc * (s + z) / (s + p)
    % For lag, z > p
    if nargin < 1, Kc = []; end
    if nargin < 2, z = []; end
    if nargin < 3, p = []; end
    sys = tf(Kc * [1, z], [1, p]);
end
