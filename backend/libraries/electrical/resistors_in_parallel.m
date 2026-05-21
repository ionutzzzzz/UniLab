function R_eq = resistors_in_parallel(R_array)
    R_eq = 1 / sum(1 ./ R_array);
end
