function sys = lead_compensator(Kc, z, p)
    % LEAD_COMPENSATOR Create a lead compensator C(s) = Kc * (s + z) / (s + p)
    % For lead, z < p
    sys = tf(Kc * [1, z], [1, p]);
end
