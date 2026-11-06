function C_eq = capacitors_in_parallel(C_array)
    if nargin < 1, C_array = []; end
    C_eq = sum(C_array);
end
