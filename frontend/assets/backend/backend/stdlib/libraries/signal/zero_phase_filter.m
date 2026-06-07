function y = zero_phase_filter(b, a, x)
    % ZERO_PHASE_FILTER Forward-backward filtering for zero phase distortion
    y = filtfilt(b, a, x);
end
