function k_H = henry_law_constant(concentration, partial_pressure)
    % HENRY_LAW_CONSTANT Calculate Henry's law constant
    % C = k_H * P
    k_H = concentration / partial_pressure;
end
