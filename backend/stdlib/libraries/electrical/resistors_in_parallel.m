function R_eq = resistors_in_parallel(R_array)
    if nargin < 1, R_array = []; end
    R_eq = 1 / sum(1 ./ R_array);
end
