function [Z, phase] = impedance_freq(R, L, C, f)
    % IMPEDANCE_FREQ Calculates impedance of an RLC circuit over frequency
    % [Z, phase] = impedance_freq(R, L, C, f)
    
    w = 2 * pi() * f;
    Z_val = R + 1j*w*L + 1/(1j*w*C);
    
    Z = abs(Z_val);
    phase = angle(Z_val);
end
