function pm = phase_margin_calc(sys)
    % PHASE_MARGIN_CALC Calculate phase margin of a system
    [mag, phase, w] = bode(sys);
    % Find frequency where magnitude is 1 (0 dB)
    idx = find(mag <= 1, 1);
    if isempty(idx)
        pm = inf;
    else
        pm = 180 + phase(idx);
    end
end
