function sys = lag_compensator(Kc, z, p)
    % LAG_COMPENSATOR Create a lag compensator C(s) = Kc * (s + z) / (s + p)
    % For lag, z > p
    sys = tf(Kc * [1, z], [1, p]);
end
