function gm = gain_margin_calc(sys)
    % GAIN_MARGIN_CALC Calculate gain margin of a system
    if nargin < 1, sys = []; end
    [mag, phase, w] = bode(sys);
    % Find frequency where phase is -180
    idx = find(phase <= -180, 1);
    if isempty(idx)
        gm = inf;
    else
        gm = 1 / mag(idx);
    end
end
