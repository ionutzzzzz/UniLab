function [pulses] = interleaved_pwm(v_ref, fs, f_carrier, num_phases)
    % INTERLEAVED_PWM Generates interleaved PWM pulses
    % num_phases: number of parallel phases (e.g., for interleaved buck)
    
    if nargin < 1, v_ref = []; end
    if nargin < 2, fs = []; end
    if nargin < 3, f_carrier = []; end
    if nargin < 4, num_phases = []; end
    t = (0:length(v_ref)-1) / fs;
    pulses = zeros(length(v_ref), num_phases);
    
    for k = 1:num_phases
        % Phase shift carrier for each phase
        phase_shift = (k - 1) / num_phases;
        carrier = 2 * abs(mod(t * f_carrier + phase_shift, 1) - 0.5);
        pulses(:, k) = v_ref > (carrier * 2 - 1);
    end
end
