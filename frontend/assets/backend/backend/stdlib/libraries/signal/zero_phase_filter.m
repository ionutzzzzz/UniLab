function y = zero_phase_filter(b, a, x)
    % ZERO_PHASE_FILTER Forward-backward filtering for zero phase distortion
    if nargin < 1, b = []; end
    if nargin < 2, a = []; end
    if nargin < 3, x = []; end
    y = filtfilt(b, a, x);
end
