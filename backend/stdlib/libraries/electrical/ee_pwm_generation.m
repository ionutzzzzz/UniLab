function [pulses, carrier] = ee_pwm_generation(v_ref, fs, f_carrier, type)
    % EE_PWM_GENERATION Generates PWM pulses for a reference signal
    % [pulses, carrier] = ee_pwm_generation(v_ref, fs, f_carrier, type)
    % type: 'sawtooth' or 'triangle'
    
    if nargin < 1, v_ref = []; end
    if nargin < 2, fs = []; end
    if nargin < 3, f_carrier = []; end
    if nargin < 4, type = 'triangle'; end
    
    t = (0:length(v_ref)-1) / fs;
    
    if strcmp(type, 'sawtooth')
        carrier = mod(t * f_carrier, 1);
    else
        % Triangle wave
        carrier = 2 * abs(mod(t * f_carrier + 0.5, 1) - 0.5);
    end
    
    pulses = v_ref > (carrier * 2 - 1); % Assuming v_ref in [-1, 1]
end
