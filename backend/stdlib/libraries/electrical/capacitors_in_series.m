function C_eq = capacitors_in_series(C_array)
    C_eq = 1 / sum(1 ./ C_array);
end
