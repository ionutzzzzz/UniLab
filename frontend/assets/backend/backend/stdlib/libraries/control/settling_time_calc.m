function ts = settling_time_calc(zeta, wn, criterion)
    % SETTLING_TIME_CALC Calculate settling time for a second-order system
    if nargin < 1, zeta = []; end
    if nargin < 2, wn = []; end
    if nargin < 3, criterion = 0.02; end
    if criterion == 0.02
        ts = 4 / (zeta * wn);
    else
        ts = 3 / (zeta * wn);
    end
end
