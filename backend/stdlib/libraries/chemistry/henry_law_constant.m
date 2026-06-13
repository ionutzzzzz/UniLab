function k_H = henry_law_constant(concentration, partial_pressure)
    % HENRY_LAW_CONSTANT Calculate Henry's law constant
    % C = k_H * P
    if nargin < 1, concentration = []; end
    if nargin < 2, partial_pressure = []; end
    k_H = concentration / partial_pressure;
end
