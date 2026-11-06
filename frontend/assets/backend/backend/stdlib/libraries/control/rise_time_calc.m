function tr = rise_time_calc(zeta, wn)
    % RISE_TIME_CALC Calculate rise time for a second-order system
    % tr approx (0.8 + 2.5 * zeta) / wn
    if nargin < 1, zeta = []; end
    if nargin < 2, wn = []; end
    tr = (0.8 + 2.5 * zeta) / wn;
end
