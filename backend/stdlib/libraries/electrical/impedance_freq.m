function [Z, phase] = impedance_freq(R, L, C, f)
    % IMPEDANCE_FREQ Calculates impedance of an RLC circuit over frequency
    % [Z, phase] = impedance_freq(R, L, C, f)
    
    if nargin < 1, R = []; end
    if nargin < 2, L = []; end
    if nargin < 3, C = []; end
    if nargin < 4, f = []; end
    w = 2 * pi() * f;
    Z_val = R + 1j*w*L + 1/(1j*w*C);
    
    Z = abs(Z_val);
    phase = angle(Z_val);
end
