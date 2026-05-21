function tr = rise_time_calc(zeta, wn)
    % RISE_TIME_CALC Calculate rise time for a second-order system
    % tr approx (0.8 + 2.5 * zeta) / wn
    tr = (0.8 + 2.5 * zeta) / wn;
end
