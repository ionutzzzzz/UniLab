function sys = lead_compensator(Kc, z, p)
    % LEAD_COMPENSATOR Create a lead compensator C(s) = Kc * (s + z) / (s + p)
    % For lead, z < p
    if nargin < 1, Kc = []; end
    if nargin < 2, z = []; end
    if nargin < 3, p = []; end
    sys = tf(Kc * [1, z], [1, p]);
end
